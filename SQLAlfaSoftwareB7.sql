-- ==========================================================
-- | B7 (varianta Vizor): raport cu grupari si subtotaluri  |
-- ==========================================================

-- View-ul pe care se sprijina raportul. Aduce intr-un singur loc tot ce trebuie
-- filtrat si agregat, ca procedura sa ramana citibila.
-- TermenSLA = momentul limita pana la care ticketul trebuia rezolvat; comparatia
-- DataRezolvare <= TermenSLA e mai clara decat calculul in ore din vw_RespectareSLA.
GO
CREATE OR ALTER VIEW vw_TicheteRaportare AS
    SELECT
        t.idTicket,
        t.Titlu,
        t.DataCreare,
        t.DataRezolvare,
        t.idCategorie,
        rtrim(c.Denumire)                          AS Categorie,
        c.SLA_ore,
        dateadd(HOUR, c.SLA_ore, t.DataCreare)     AS TermenSLA,
        t.idPrioritate,
        rtrim(p.Denumire)                          AS Prioritate,
        p.Nivel                                    AS NivelPrioritate, -- 1 = critic, pentru sortare
        t.Stare                                    AS idStare, -- in Tickete coloana se numeste Stare
        rtrim(s.Denumire)                          AS Stare,
        s.TipStare,
        rtrim(t.idSolicitant)                      AS idSolicitant,
        rtrim(t.idResponsabil)                     AS idResponsabil, -- rtrim pentru ca Marca e char(6)
        cast(datediff(MINUTE, t.DataCreare, t.DataRezolvare) / 60.0 AS DECIMAL(18,4)) AS TimpRezolvareOre
    FROM Tickete t
    JOIN Categorii   c ON c.idCategorie  = t.idCategorie
    JOIN Prioritati  p ON p.idPrioritate = t.idPrioritate
    JOIN StariTicket s ON s.idStare      = t.Stare;
GO

-- Raportul propriu-zis. Se apeleaza dintr-un buton de macheta.
-- @actiune: V = deschidere in Vizor (implicit), E = generare Excel.
-- Subtotalurile se calculeaza aici, cu GROUPING SETS, nu in designerul Vizor -
-- asa procentul de SLA iese ponderat corect si pe subtotal, si pe total general.
GO
CREATE OR ALTER PROCEDURE wOPRaportVizorTickete @sesiune varchar(50), @parXML xml -- conventie pentru fiecare procedura: denumirea incepe cu w pentru web si are acesti doi parametrii trimisi de catre frame
AS
BEGIN TRY
    SET NOCOUNT ON;

    DECLARE @msgEroare VARCHAR(MAX), @utilizator VARCHAR(100),
            @dataDeLaText VARCHAR(30), @dataPanaLaText VARCHAR(30),
            @dataDeLa DATE, @dataPanaLa DATE,
            @idCategorieText VARCHAR(30), @idResponsabilText VARCHAR(30), @idStareText VARCHAR(30),
            @idCategorie INT, @idResponsabil VARCHAR(6), @idStare INT,
            @denCategorie NVARCHAR(100), @denResponsabil NVARCHAR(150), @denStare NVARCHAR(100),
            @textPerioada VARCHAR(200), @actiune VARCHAR(1),
            @nrColoane INT, @px XML;

    EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT

    -- Citirea parametrilor. Se foloseste (//@nume)[last()] ca sa fie gasit atributul
    -- indiferent pe ce nivel din XML il pune frame-ul.
    SELECT @dataDeLaText      = nullif(ltrim(rtrim(@parXML.value('string((//@viz_datadela)[last()])',      'varchar(30)'))), ''),
           @dataPanaLaText    = nullif(ltrim(rtrim(@parXML.value('string((//@viz_datapanala)[last()])',    'varchar(30)'))), ''),
           @idCategorieText   = nullif(ltrim(rtrim(@parXML.value('string((//@viz_idcategorie)[last()])',   'varchar(30)'))), ''),
           @idResponsabilText = nullif(ltrim(rtrim(@parXML.value('string((//@viz_idresponsabil)[last()])', 'varchar(30)'))), ''),
           @idStareText       = nullif(ltrim(rtrim(@parXML.value('string((//@viz_idstare)[last()])',       'varchar(30)'))), ''),
           @actiune           = upper(isnull(nullif(@parXML.value('string((//@actiune)[last()])', 'varchar(1)'), ''), 'V'))

    IF @actiune NOT IN ('V', 'E') SET @actiune = 'V'

    -- Conversia perioadei: se accepta ISO, formatul romanesc si cel implicit al serverului
    IF @dataDeLaText IS NOT NULL
    BEGIN
        SET @dataDeLa = coalesce(TRY_CONVERT(DATE, @dataDeLaText, 126),
                                 TRY_CONVERT(DATE, @dataDeLaText, 104),
                                 TRY_CONVERT(DATE, @dataDeLaText))
        IF @dataDeLa IS NULL RAISERROR(N'Data de inceput nu are un format valid.', 16, 1)
    END

    IF @dataPanaLaText IS NOT NULL
    BEGIN
        SET @dataPanaLa = coalesce(TRY_CONVERT(DATE, @dataPanaLaText, 126),
                                   TRY_CONVERT(DATE, @dataPanaLaText, 104),
                                   TRY_CONVERT(DATE, @dataPanaLaText))
        IF @dataPanaLa IS NULL RAISERROR(N'Data de sfarsit nu are un format valid.', 16, 1)
    END

    IF (@dataDeLa IS NOT NULL AND @dataPanaLa IS NOT NULL AND @dataDeLa > @dataPanaLa)
        RAISERROR(N'Data de inceput nu poate fi mai mare decat data de sfarsit.', 16, 1)

    -- Conversia identificatorilor. NULLIF(...,0) trateaza si cazul in care frame-ul trimite 0 pentru "toate".
    SET @idCategorie   = nullif(TRY_CONVERT(INT, @idCategorieText), 0)
    SET @idStare       = nullif(TRY_CONVERT(INT, @idStareText), 0)
    SET @idResponsabil = nullif(ltrim(rtrim(@idResponsabilText)), '') -- ramane text: Marca e char(6), nu numar

    IF (@idCategorieText IS NOT NULL AND TRY_CONVERT(INT, @idCategorieText) IS NULL)
        RAISERROR(N'Categoria selectata nu este valida.', 16, 1)
    IF (@idStareText IS NOT NULL AND TRY_CONVERT(INT, @idStareText) IS NULL)
        RAISERROR(N'Starea selectata nu este valida.', 16, 1)

    -- Denumirile filtrelor, pentru antetul raportului
    IF @idCategorie IS NULL SET @denCategorie = N'Toate'
    ELSE
    BEGIN
        SELECT @denCategorie = c.Denumire FROM Categorii c WHERE c.idCategorie = @idCategorie
        IF @denCategorie IS NULL RAISERROR(N'Categoria selectata nu exista.', 16, 1)
    END

    IF @idStare IS NULL SET @denStare = N'Toate'
    ELSE
    BEGIN
        SELECT @denStare = s.Denumire FROM StariTicket s WHERE s.idStare = @idStare
        IF @denStare IS NULL RAISERROR(N'Starea selectata nu exista.', 16, 1)
    END

    IF @idResponsabil IS NULL SET @denResponsabil = N'Toti'
    ELSE
    BEGIN
        SELECT @denResponsabil = rtrim(p.Nume) FROM Personal p WHERE rtrim(p.Marca) = rtrim(@idResponsabil)
        IF @denResponsabil IS NULL RAISERROR(N'Responsabilul selectat nu exista.', 16, 1)
    END

    SET @textPerioada =
        CASE WHEN @dataDeLa IS NULL AND @dataPanaLa IS NULL
                  THEN 'Perioada: toate datele'
             WHEN @dataDeLa IS NOT NULL AND @dataPanaLa IS NULL
                  THEN 'Perioada: de la ' + convert(varchar(10), @dataDeLa, 103)
             WHEN @dataDeLa IS NULL AND @dataPanaLa IS NOT NULL
                  THEN 'Perioada: pana la ' + convert(varchar(10), @dataPanaLa, 103)
             ELSE 'Perioada: ' + convert(varchar(10), @dataDeLa, 103)
                  + ' - ' + convert(varchar(10), @dataPanaLa, 103)
        END

    IF object_id(N'tempdb..#coloane', N'U') IS NOT NULL DROP TABLE #coloane
    IF object_id(N'tempdb..#antet',   N'U') IS NOT NULL DROP TABLE #antet
    IF object_id(N'tempdb..#date',    N'U') IS NOT NULL DROP TABLE #date

    CREATE TABLE #coloane (dencol varchar(200), numecol varchar(200), tipcol varchar(10), _format varchar(20))
    CREATE TABLE #antet   (titlu varchar(500), _font_dim int, _font_atribut varchar(50),
                           _culoare_fundal varchar(50), _culoare varchar(50),
                           _aliniament varchar(50), cols_merge int)
    CREATE TABLE #date    (Categorie nvarchar(100), Prioritate nvarchar(100),
                           NrTickete int, NrRezolvate int, TimpMediuRezolvareOre decimal(18,2),
                           NrSLARespectate int, ProcentSLARespectat decimal(18,2),
                           SortCategorie nvarchar(100), SortNivel int, SortPrioritate int, TipRand int)

    INSERT INTO #coloane (numecol, dencol, tipcol, _format) VALUES
        ('Categorie',             'Categorie',                  'C', NULL),
        ('Prioritate',            'Prioritate',                 'C', NULL),
        ('NrTickete',             'Nr. tickete',                'N', '#,##0'),
        ('NrRezolvate',           'Nr. rezolvate',              'N', '#,##0'),
        ('TimpMediuRezolvareOre', 'Timp mediu rezolvare (ore)', 'N', '#,##0.00'),
        ('NrSLARespectate',       'SLA respectate',             'N', '#,##0'),
        ('ProcentSLARespectat',   'SLA respectat (%)',          'N', '#,##0.00')

    SELECT @nrColoane = count(*) FROM #coloane

    -- GROUPING SETS produce trei niveluri deodata: detaliu (categorie+prioritate),
    -- subtotal de categorie si total general. GROUPING() spune pe care dintre ele suntem.
    ;WITH TicketeFiltrate AS (
        SELECT r.idCategorie, r.Categorie, r.idPrioritate, r.Prioritate, r.NivelPrioritate,
               r.DataRezolvare, r.TermenSLA, r.TimpRezolvareOre
        FROM   vw_TicheteRaportare r
        WHERE (@dataDeLa       IS NULL OR r.DataCreare >= @dataDeLa)
          AND (@dataPanaLa     IS NULL OR r.DataCreare <  dateadd(DAY, 1, convert(datetime, @dataPanaLa)))
          AND (@idCategorie    IS NULL OR r.idCategorie = @idCategorie)
          AND (@idResponsabil  IS NULL OR rtrim(r.idResponsabil) = rtrim(@idResponsabil))
          AND (@idStare        IS NULL OR r.idStare = @idStare)
    ),
    Indicatori AS (
        SELECT f.idCategorie, f.Categorie, f.idPrioritate, f.Prioritate, f.NivelPrioritate,
               GROUPING(f.idCategorie)  AS TotalGeneral,   -- 1 = randul e totalul general
               GROUPING(f.idPrioritate) AS TotalCategorie, -- 1 = randul e subtotal de categorie
               count(*) AS NrTickete,
               sum(CASE WHEN f.DataRezolvare IS NOT NULL THEN 1 ELSE 0 END) AS NrRezolvate,
               cast(avg(cast(f.TimpRezolvareOre AS DECIMAL(18,4))) AS DECIMAL(18,2)) AS TimpMediuRezolvareOre, -- AVG ignora NULL, deci media e doar peste ticketele rezolvate
               sum(CASE WHEN f.DataRezolvare IS NOT NULL AND f.TermenSLA IS NOT NULL
                         AND f.DataRezolvare <= f.TermenSLA THEN 1 ELSE 0 END) AS NrSLARespectate,
               sum(CASE WHEN f.DataRezolvare IS NOT NULL AND f.TermenSLA IS NOT NULL
                        THEN 1 ELSE 0 END) AS NrSLAEvaluabile -- numitorul procentului: doar ticketele care se pot judeca
        FROM   TicketeFiltrate f
        GROUP BY GROUPING SETS (
            (f.idCategorie, f.Categorie, f.idPrioritate, f.Prioritate, f.NivelPrioritate),
            (f.idCategorie, f.Categorie),
            ()
        )
    )
    INSERT INTO #date (Categorie, Prioritate, NrTickete, NrRezolvate, TimpMediuRezolvareOre,
                       NrSLARespectate, ProcentSLARespectat,
                       SortCategorie, SortNivel, SortPrioritate, TipRand)
    SELECT
        CASE WHEN i.TotalGeneral = 1 THEN N'TOTAL GENERAL'
             ELSE isnull(i.Categorie, N'Fara categorie') END,
        CASE WHEN i.TotalGeneral   = 1 THEN N''
             WHEN i.TotalCategorie = 1 THEN N'TOTAL CATEGORIE'
             ELSE isnull(i.Prioritate, N'Fara prioritate') END,
        i.NrTickete,
        i.NrRezolvate,
        i.TimpMediuRezolvareOre,
        i.NrSLARespectate,
        cast(CASE WHEN isnull(i.NrSLAEvaluabile, 0) = 0 THEN 0
                  ELSE 100.0 * i.NrSLARespectate / i.NrSLAEvaluabile END AS DECIMAL(18,2)),
        CASE WHEN i.TotalGeneral = 1 THEN N'ZZZZZZZZZZ' -- forteaza totalul general la finalul sortarii alfabetice
             ELSE isnull(i.Categorie, N'Fara categorie') END,
        CASE WHEN i.TotalGeneral   = 1 THEN 3
             WHEN i.TotalCategorie = 1 THEN 2
             ELSE 1 END,
        isnull(cast(i.NivelPrioritate AS int), 999999), -- sortare dupa nivel (1 = critic), nu alfabetic; cast pentru ca Nivel e TINYINT (max 255) iar ISNULL ia tipul primului argument
        CASE WHEN i.TotalGeneral   = 1 THEN 2
             WHEN i.TotalCategorie = 1 THEN 1
             ELSE 0 END
    FROM Indicatori i

    -- Antetul: titlu, filtrele aplicate si cine a generat raportul
    INSERT INTO #antet (titlu, _font_dim, _font_atribut, _culoare, _culoare_fundal, _aliniament, cols_merge)
    SELECT 'Raport Helpdesk - indicatori pe categorie si prioritate', 15, 'bold', '', '', 'center', @nrColoane
    UNION ALL SELECT '',                                                                12, '',     '', '', 'left', @nrColoane
    UNION ALL SELECT @textPerioada,                                                     12, 'bold', '', '', 'left', @nrColoane
    UNION ALL SELECT 'Categorie: '   + convert(varchar(100), @denCategorie),            12, '',     '', '', 'left', @nrColoane
    UNION ALL SELECT 'Stare: '       + convert(varchar(100), @denStare),                12, '',     '', '', 'left', @nrColoane
    UNION ALL SELECT 'Responsabil: ' + convert(varchar(150), @denResponsabil),          12, '',     '', '', 'left', @nrColoane
    UNION ALL SELECT 'Generat la: '  + convert(char(10), getdate(), 103) + ' '
                                     + convert(char(5),  getdate(), 114)
                                     + ' | Utilizator: ' + isnull(@utilizator, ''),      12, '',     '', '', 'left', @nrColoane
    UNION ALL SELECT '',                                                                12, '',     '', '', 'left', @nrColoane

    SET @px = (
        SELECT 'Raport_Helpdesk_' + convert(char(8), getdate(), 112) AS numeFisier,
               @actiune AS actiune,
               (SELECT * FROM #coloane FOR XML RAW, TYPE) AS coloane,
               (SELECT d.Categorie, d.Prioritate, d.NrTickete, d.NrRezolvate,
                       d.TimpMediuRezolvareOre, d.NrSLARespectate, d.ProcentSLARespectat,
                       11 AS _font_dim,
                       CASE WHEN d.TipRand IN (1, 2) THEN 'bold' ELSE NULL END AS _font_atribut -- subtotalurile si totalul ies ingrosate
                FROM #date d
                ORDER BY d.SortCategorie, d.SortNivel, d.SortPrioritate
                FOR XML RAW, TYPE) AS [date],
               (SELECT 'Raport Helpdesk' AS numeSheet, 14 AS _font_dim, 'bold' AS _font_atribut,
                       '#ffffff' AS _culoare, '#1e2161' AS _culoare_fundal
                FOR XML RAW, TYPE) AS info,
               (SELECT * FROM #antet FOR XML RAW, TYPE) AS antet
        FOR XML RAW('row'), TYPE)

    EXEC GenExcelsauVizualizare @sesiune=@sesiune, @parXML=@px
END TRY
BEGIN CATCH
    SET @msgEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
    RAISERROR(@msgEroare, 16, 1)
END CATCH
GO

-- Procedura de pregatire a machetei de parametri. ASiS o apeleaza inainte sa deschida
-- fereastra si foloseste randul intors ca sa precompleteze campurile.
-- Perioada implicita e luna curenta, ca utilizatorul sa nu porneasca de la formular gol.
--
-- Datele se trimit in ISO (stil 23). E important: wOPRaportVizorTickete le parseaza cu
-- coalesce(126, 104, implicit). Daca aici s-ar folosi stilul 101, '07/01/2026' ar esua pe
-- 126, ar reusi pe 104 si ar fi citit ca 7 ianuarie in loc de 1 iulie.
GO
CREATE OR ALTER PROCEDURE wOPRaportVizorTickete_p @sesiune varchar(50), @parXML xml -- conventie pentru fiecare procedura: denumirea incepe cu w pentru web si are acesti doi parametrii trimisi de catre frame
AS
BEGIN TRY
    SET NOCOUNT ON;

    DECLARE @utilizator VARCHAR(100), @msgEroare VARCHAR(MAX),
            @dataDeLa DATE, @dataPanaLa DATE;

    EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT

    SET @dataDeLa   = dbo.bom(getdate())      -- prima zi a lunii curente
    SET @dataPanaLa = cast(getdate() AS date) -- azi, nu sfarsitul lunii: nu are sens sa ceri date din viitor

    SELECT convert(varchar(10), @dataDeLa,   23) AS viz_datadela,
           convert(varchar(10), @dataPanaLa, 23) AS viz_datapanala,
           ''  AS viz_idcategorie,   -- gol = toate categoriile
           ''  AS viz_idresponsabil, -- gol = toti responsabilii
           ''  AS viz_idstare,       -- gol = toate starile
           'V' AS actiune            -- V = deschidere in Vizor, E = export Excel
    FOR XML RAW, ROOT('Date')
END TRY
BEGIN CATCH
    SELECT '1' AS inchideFereastra FOR XML RAW, ROOT('Mesaje') -- daca pregatirea esueaza, macheta nu se mai deschide
    SET @msgEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
    RAISERROR(@msgEroare, 16, 1)
END CATCH
GO

INSERT INTO service.CheiOAuth (access_token, alias, utilizator, dataora)
VALUES ('helpdesk-test-2026', 'HELPDESK', 'razvan', getdate())

EXEC pAPILinkTickete
       @sesiune = NULL,
       @parXML  = '<row hash="helpdesk-test-2026" categorie="Retea" stare="Inchis"
                        dataStart="2026-01-01" dataStop="2026-07-31"/>'

EXEC pAPILinkTicketNou
     @sesiune = NULL,
     @parXML  = '<row hash="helpdesk-test-2026"/>',
     @json    = '{"titlu":"Test API","descriere":"Creat din SSMS",
                  "categorie":"Hardware","prioritate":"Urgent","solicitant":"852"}'
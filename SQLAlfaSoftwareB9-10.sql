-- =================================================
-- | B9 + B10: API REST (JSON) pentru tickete      |
-- =================================================

-- Serviciul asisservice primeste requestul HTTP, transforma query
-- string-ul in @parXML si apeleaza procedura. Procedura:
--   1. isi citeste parametrii din @parXML
--   2. logheaza apelul cu salvareLogAPI
--   3. valideaza cheia de acces cu validareCheieAPI, pe un alias din service.CheiOAuth
--   4. intoarce raspunsul cu FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
--
-- INAINTE DE FOLOSIRE: trebuie creata cheia in service.CheiOAuth cu alias 'HELPDESK',
-- altfel validareCheieAPI respinge orice apel.

-- B9. API GET - lista de tickete in JSON
-- GET .../pAPILinkTickete?hash=<cheie>&categorie=Retea&stare=Inchis&responsabil=856
--                        &dataStart=2026-01-01&dataStop=2026-07-31
-- Toate filtrele sunt optionale. Datele se trimit in format ISO (yyyy-mm-dd).
GO
CREATE OR ALTER PROCEDURE pAPILinkTickete
    @sesiune VARCHAR(50) = NULL,
    @parXML  XML         = NULL
AS
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
BEGIN TRY
    DECLARE @msgEroare VARCHAR(MAX), @categorie VARCHAR(100), @stare VARCHAR(50),
            @responsabil VARCHAR(20), @dataStart DATE, @dataStop DATE,
            @hash VARCHAR(100), @total INT

    -- parametrii vin din query string, convertit in @parXML de asisservice
    select @categorie   = @parXML.value('(/row/@categorie)[1]',   'varchar(100)'),
           @stare       = @parXML.value('(/row/@stare)[1]',       'varchar(50)'),
           @responsabil = @parXML.value('(/row/@responsabil)[1]', 'varchar(20)'),
           @dataStart   = TRY_CONVERT(date, @parXML.value('(/row/@dataStart)[1]', 'varchar(20)'), 23), -- 23 = ISO yyyy-mm-dd
           @dataStop    = TRY_CONVERT(date, @parXML.value('(/row/@dataStop)[1]',  'varchar(20)'), 23),
           @hash        = @parXML.value('(/row/@hash)[1]',        'varchar(100)')

    exec salvareLogAPI    @sesiune=@sesiune, @parXML=@parXML
    exec validareCheieAPI @cheie=@hash, @alias='HELPDESK'

    IF object_id('tempdb..#tkApi') IS NOT NULL DROP TABLE #tkApi
    CREATE TABLE #tkApi (
        idTicket int, titlu nvarchar(200), descriere nvarchar(max),
        categorie nvarchar(100), prioritate nvarchar(50), stare nvarchar(50), tipStare varchar(20),
        solicitant nvarchar(50), responsabil nvarchar(50),
        dataCreare varchar(10), dataRezolvare varchar(10),
        oreRezolvare decimal(15,2), SLA_ore int, inTermen bit, minuteLucrate int)

    INSERT INTO #tkApi
    SELECT t.idTicket, t.Titlu, t.Descriere,
           rtrim(c.Denumire), rtrim(p.Denumire), rtrim(s.Denumire), s.TipStare,
           rtrim(sol.Nume), isnull(rtrim(resp.Nume), ''), -- rtrim pentru ca Nume e char(50)
           convert(varchar(10), t.DataCreare, 23),        -- ISO in raspuns, ca sa poata fi parsat de orice client
           convert(varchar(10), t.DataRezolvare, 23),
           convert(decimal(15,2), datediff(MINUTE, t.DataCreare, t.DataRezolvare) / 60.0),
           c.SLA_ore,
           CASE WHEN t.DataRezolvare IS NULL THEN NULL -- null, nu 0: inca nu se poate spune daca s-a respectat SLA
                WHEN datediff(MINUTE, t.DataCreare, t.DataRezolvare) / 60.0 <= c.SLA_ore THEN 1
                ELSE 0 END,
           isnull(act.minuteLucrate, 0)
    FROM   Tickete t
    JOIN   Categorii   c    ON c.idCategorie  = t.idCategorie
    JOIN   Prioritati  p    ON p.idPrioritate = t.idPrioritate
    JOIN   StariTicket s    ON s.idStare      = t.Stare -- in Tickete coloana se numeste Stare, nu idStare
    JOIN   Personal    sol  ON sol.Marca      = t.idSolicitant
    LEFT   JOIN Personal resp ON resp.Marca   = t.idResponsabil
    OUTER  APPLY (SELECT minuteLucrate = SUM(a.DurataMinute)
                  FROM ActivitatiTicket a WHERE a.idTicket = t.idTicket) act
    WHERE (@categorie   IS NULL OR rtrim(c.Denumire) = @categorie)
      AND (@stare       IS NULL OR rtrim(s.Denumire) = @stare)
      AND (@responsabil IS NULL OR rtrim(t.idResponsabil) = @responsabil)
      AND (@dataStart   IS NULL OR t.DataCreare >= @dataStart)
      AND (@dataStop    IS NULL OR t.DataCreare <  dateadd(day, 1, @dataStop))

    select @total = count(*) from #tkApi

    -- raspunsul: { "success": true, "total": n, "date": [ ... ] }
    select cast(1 as bit) as [success],
           @total         as [total],
           ( select * from #tkApi order by idTicket desc for json path ) as [date]
    for json path, without_array_wrapper
END TRY
BEGIN CATCH
    set @msgEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@procid) + ')'
    RAISERROR (@msgEroare, 16, 1)
END CATCH
GO

-- B10. API POST - creare ticket nou din JSON
-- POST .../pAPILinkTicketNou?hash=<cheie>
-- Body: { "titlu": "...", "descriere": "...", "categorie": "Retea",
--         "prioritate": "Urgent", "solicitant": "852" }
-- categorie / prioritate se dau ca denumire, solicitant ca marca din Personal.
GO
CREATE OR ALTER PROCEDURE pAPILinkTicketNou
    @sesiune VARCHAR(50)   = NULL,
    @parXML  XML           = NULL,
    @json    NVARCHAR(MAX) = NULL -- body-ul JSON; daca asisservice il trimite ca atribut, se citeste din @parXML mai jos
AS
BEGIN TRY
    DECLARE @msgEroare VARCHAR(MAX), @hash VARCHAR(100),
            @titlu NVARCHAR(200), @descriere NVARCHAR(MAX),
            @categorie NVARCHAR(100), @prioritate NVARCHAR(50), @solicitant CHAR(6),
            @idCategorie INT, @idPrioritate INT, @idStareNoua INT, @idTicket INT

    set @hash = @parXML.value('(/row/@hash)[1]', 'varchar(100)')

    exec salvareLogAPI    @sesiune=@sesiune, @parXML=@parXML
    exec validareCheieAPI @cheie=@hash, @alias='HELPDESK'

    -- body-ul poate veni fie ca parametru direct, fie ca atribut in @parXML
    set @json = isnull(@json, @parXML.value('(/row/@json)[1]', 'nvarchar(max)'))

    IF isjson(@json) <> 1
        RAISERROR('Body-ul trimis nu este JSON valid!', 16, 1)

    -- OPENJSON cu schema explicita: mapeaza cheile din JSON pe coloane tipizate
    select @titlu      = j.titlu,
           @descriere  = j.descriere,
           @categorie  = j.categorie,
           @prioritate = j.prioritate,
           @solicitant = nullif(rtrim(j.solicitant), '')
    from   OPENJSON(@json) WITH (
               titlu      NVARCHAR(200) '$.titlu',
               descriere  NVARCHAR(MAX) '$.descriere',
               categorie  NVARCHAR(100) '$.categorie',
               prioritate NVARCHAR(50)  '$.prioritate',
               solicitant VARCHAR(6)    '$.solicitant'
           ) j

    -- verificari: campuri obligatorii prezente si nomenclatoare existente
    IF len(isnull(@titlu, '')) = 0
        RAISERROR('Campul "titlu" este obligatoriu!', 16, 1)

    select @idCategorie = idCategorie FROM Categorii WHERE rtrim(Denumire) = @categorie
    IF @idCategorie IS NULL
        RAISERROR('Categoria trimisa nu exista! Valori valide: Hardware, Software, Acces, Retea, Email.', 16, 1)

    select @idPrioritate = idPrioritate FROM Prioritati WHERE rtrim(Denumire) = @prioritate
    IF @idPrioritate IS NULL
        RAISERROR('Prioritatea trimisa nu exista! Valori valide: Critic, Urgent, Normal, Scazut.', 16, 1)

    IF @solicitant IS NULL OR NOT EXISTS (SELECT 1 FROM Personal WHERE Marca = @solicitant)
        RAISERROR('Solicitantul trimis nu exista in Personal!', 16, 1)

    select @idStareNoua = idStare FROM StariTicket WHERE Denumire = N'Nou'

    -- ticketul si prima linie de jurnal trebuie sa apara impreuna sau deloc
    BEGIN TRAN
        INSERT INTO Tickete (Titlu, Descriere, idCategorie, idPrioritate,
                             idSolicitant, idResponsabil, Stare) -- fara responsabil: ticketul e Nou
        VALUES (@titlu, @descriere, @idCategorie, @idPrioritate,
                @solicitant, NULL, @idStareNoua)

        set @idTicket = SCOPE_IDENTITY()

        INSERT INTO JurnalTickete (idTicket, Stare, Utilizator, Comentariu)
        VALUES (@idTicket, @idStareNoua, @solicitant, N'Ticket creat prin API')
    COMMIT TRAN

    -- raspunsul: { "success": true, "idTicket": 3050, "mesaj": "..." }
    select cast(1 as bit)                             as [success],
           @idTicket                                  as [idTicket],
           'Ticket creat cu starea Nou'               as [mesaj]
    for json path, without_array_wrapper
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRAN
    set @msgEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@procid) + ')'
    RAISERROR (@msgEroare, 16, 1)
END CATCH
GO
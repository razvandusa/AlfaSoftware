-- ==============================================================
-- | B4: Machete CRUD (ASiSerp): categorii, prioritati, tickete |
-- ==============================================================

-- 1.1 Categorii - wIaCategorii
CREATE OR ALTER PROCEDURE wIaCategorii @sesiune varchar(50), @parXML xml -- conventie pentru fiecare procedura: denumirea incepe cu w pentru web si are acesti doi parametrii trimisi de catre frame
AS
DECLARE @msgEroare VARCHAR(8000), @utilizator VARCHAR(50) -- declaram 2 variabile
BEGIN TRY
    exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT -- output pentru ca variabilele sa poata sa fie modificate de procedura. In aceasta linie legam variabilele noastre declarate mai sus de variabilele folosite de procedura
    select idCategorie, Denumire, isnull(Descriere, '') as Descriere, SLA_ore from Categorii -- isnull pentru ca FOR XML RAW omite complet atributele NULL, iar macheta nu ar mai primi campul
    FOR XML RAW -- convertim in XML
END TRY
BEGIN CATCH
    set @msgEroare=error_message() + '(' + OBJECT_NAME(@@procid) + ')' -- afisam eroarea pe care o prindem folosind error_message ca sa luam eroarea si luam id-ul procedurii apelate ca sa punem si numele ei in eroare
    RAISERROR (@msgEroare, 16, 1)
END CATCH

-- 1.2 Categorii - wScriuCategorii
GO
CREATE OR ALTER PROCEDURE wScriuCategorii @sesiune varchar(50), @parXML xml -- conventie pentru fiecare procedura: denumirea incepe cu w pentru web si are acesti doi parametrii trimisi de catre frame
AS
DECLARE @msgEroare VARCHAR(8000), @utilizator VARCHAR(50), @idCategorie INT, @Denumire NVARCHAR(100), @Descriere NVARCHAR(400), @SLA_ore INT, @update INT
BEGIN TRY
    exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT -- output pentru ca variabilele sa poata sa fie modificate de procedura. In aceasta linie legam variabilele noastre declarate mai sus de variabilele folosite de procedura

    select @idCategorie = @parXML.value('/row[1]/@idCategorie', 'int'), -- citim primul rand si id-ul
            @Denumire = isnull(@parXML.value('/row[1]/@Denumire', 'nvarchar(100)'), ''), -- citim primul rand si denumirea
            @Descriere = isnull(@parXML.value('/row[1]/@Descriere', 'nvarchar(400)'), ''), -- citim primul rand si descrierea
            @SLA_ore = isnull(@parXML.value('/row[1]/@SLA_ore', 'int'), 0), -- citim primul rand si sla_ore; isnull ca sa nu ocoleasca validarea de mai jos (NULL <= 0 da UNKNOWN, nu TRUE)
            @update = isnull(@parXML.value('/row[1]/@update', 'bit'), 0)

    -- verificari de business
    if len(@denumire) = 0
        RAISERROR('Completati denumirea categorie!', 16, 1)
    if len(@descriere) = 0
        RAISERROR('Completati descriere categorie!', 16, 1)
    if @SLA_ore <= 0
        RAISERROR('Valoarea SLA nu poate fi mai mica sau egala cu 0!', 16, 1)

    IF EXISTS (SELECT * FROM Categorii C WHERE C.Denumire=@Denumire AND C.idCategorie<>ISNULL(@idCategorie, 0))
    BEGIN
        set @msgEroare = 'Denumirea exista deja pe alta categorie: ' + (SELECT TOP 1 isnull(C.Descriere, '') FROM Categorii C WHERE C.Denumire=@Denumire AND C.idCategorie<>ISNULL(@idCategorie, 0)) -- aceleasi isnull-uri ca in EXISTS, altfel @msgEroare devine NULL si RAISERROR arunca alta eroare
        RAISERROR(@msgEroare, 16, 1)
    END

    if @update = 0 -- categorie noua
    BEGIN
        INSERT INTO Categorii(Denumire, Descriere, SLA_ore)
        SELECT @Denumire, @Descriere, @SLA_ore
    END
    ELSE -- categorie pre-existenta
    BEGIN
        update Categorii
            set Denumire=@Denumire, Descriere=@Descriere, SLA_ore=@SLA_ore
        WHERE idCategorie=@idCategorie
    END
END TRY
BEGIN CATCH
    set @msgEroare=error_message() + '(' + OBJECT_NAME(@@procid) + ')' -- afisam eroarea pe care o prindem folosind error_message ca sa luam eroarea si luam id-ul procedurii apelate ca sa punem si numele ei in eroare
    RAISERROR (@msgEroare, 16, 1)
END CATCH

-- 1.3 Categorii - wStergCategorii
GO
CREATE OR ALTER PROCEDURE wStergCategorii @sesiune varchar(50), @parXML xml -- conventie pentru fiecare procedura: denumirea incepe cu w pentru web si are acesti doi parametrii trimisi de catre frame
AS
DECLARE @msgEroare VARCHAR(8000), @utilizator VARCHAR(50), @idCategorie INT, @Denumire NVARCHAR(100), @Descriere NVARCHAR(400), @SLA_ore INT, @update INT
BEGIN TRY
    exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT -- output pentru ca variabilele sa poata sa fie modificate de procedura. In aceasta linie legam variabilele noastre declarate mai sus de variabilele folosite de procedura

    select @idCategorie = @parXML.value('/row[1]/@idCategorie', 'int') -- citim primul rand si id-ul
            
    DELETE FROM Categorii WHERE idCategorie=@idCategorie
END TRY
BEGIN CATCH
    set @msgEroare=error_message() + '(' + OBJECT_NAME(@@procid) + ')' -- afisam eroarea pe care o prindem folosind error_message ca sa luam eroarea si luam id-ul procedurii apelate ca sa punem si numele ei in eroare
    RAISERROR (@msgEroare, 16, 1)
END CATCH

-- 2.1 Prioritati - wIaPrioritati
GO
CREATE OR ALTER PROCEDURE wIaPrioritati @sesiune varchar(50), @parXML xml -- conventie pentru fiecare procedura: denumirea incepe cu w pentru web si are acesti doi parametrii trimisi de catre frame
AS
DECLARE @msgEroare VARCHAR(8000), @utilizator VARCHAR(50) -- declaram 2 variabile
BEGIN TRY
    exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT -- output pentru ca variabilele sa poata sa fie modificate de procedura. In aceasta linie legam variabilele noastre declarate mai sus de variabilele folosite de procedura
    select idPrioritate, Denumire, Nivel, isnull(Culoare, '') as Culoare from Prioritati -- isnull pentru ca FOR XML RAW omite complet atributele NULL, iar macheta nu ar mai primi campul
    FOR XML RAW -- convertim in XML
END TRY
BEGIN CATCH
    set @msgEroare=error_message() + '(' + OBJECT_NAME(@@procid) + ')' -- afisam eroarea pe care o prindem folosind error_message ca sa luam eroarea si luam id-ul procedurii apelate ca sa punem si numele ei in eroare
    RAISERROR (@msgEroare, 16, 1)
END CATCH

-- 2.2 Prioritati - wScriuPrioritati
GO
CREATE OR ALTER PROCEDURE wScriuPrioritati @sesiune varchar(50), @parXML xml -- conventie pentru fiecare procedura: denumirea incepe cu w pentru web si are acesti doi parametrii trimisi de catre frame
AS
DECLARE @msgEroare VARCHAR(8000), @utilizator VARCHAR(50), @idPrioritate INT, @Denumire NVARCHAR(50), @Nivel TINYINT, @Culoare VARCHAR(7), @update INT
BEGIN TRY
    exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT -- output pentru ca variabilele sa poata sa fie modificate de procedura. In aceasta linie legam variabilele noastre declarate mai sus de variabilele folosite de procedura

    select @idPrioritate = @parXML.value('/row[1]/@idPrioritate', 'int'), -- citim primul rand si id-ul
            @Denumire = isnull(@parXML.value('/row[1]/@Denumire', 'nvarchar(50)'), ''), -- citim primul rand si denumirea
            @Nivel = isnull(@parXML.value('/row[1]/@Nivel', 'tinyint'), 0), -- citim primul rand si nivelul
            @Culoare = isnull(@parXML.value('/row[1]/@Culoare', 'varchar(7)'), ''), -- citim primul rand si culoarea
            @update = isnull(@parXML.value('/row[1]/@update', 'bit'), 0)

    -- verificari de business
    if len(@Denumire) = 0
        RAISERROR('Completati denumirea prioritatii!', 16, 1)
    if @Nivel = 0
        RAISERROR('Completati nivelul prioritatii!', 16, 1)
    if len(@Culoare) = 0
        RAISERROR('Completati culoarea prioritatii!', 16, 1)

    IF EXISTS (SELECT * FROM Prioritati P WHERE P.Denumire=@Denumire AND P.idPrioritate<>ISNULL(@idPrioritate, 0))
    BEGIN
        SET @msgEroare = 'Denumirea exista deja pe prioritatea cu ID: ' + CONVERT(VARCHAR(10), (SELECT TOP 1 P.idPrioritate FROM Prioritati P WHERE P.Denumire=@Denumire AND P.idPrioritate<>ISNULL(@idPrioritate, 0)))
        RAISERROR(@msgEroare, 16, 1)
    END

    if @update = 0 -- categorie noua
    BEGIN
        INSERT INTO Prioritati(Denumire, Nivel, Culoare)
        SELECT @Denumire, @Nivel, @Culoare
    END
    ELSE -- categorie pre-existenta
    BEGIN
        UPDATE Prioritati
        SET Denumire=@Denumire, Nivel=@Nivel, Culoare=@Culoare
        WHERE idPrioritate=@idPrioritate
    END
END TRY
BEGIN CATCH
    set @msgEroare=error_message() + '(' + OBJECT_NAME(@@procid) + ')' -- afisam eroarea pe care o prindem folosind error_message ca sa luam eroarea si luam id-ul procedurii apelate ca sa punem si numele ei in eroare
    RAISERROR (@msgEroare, 16, 1)
END CATCH

-- 2.3 Prioritati - wStergPrioritati
GO
CREATE OR ALTER PROCEDURE wStergPrioritati @sesiune varchar(50), @parXML xml -- conventie pentru fiecare procedura: denumirea incepe cu w pentru web si are acesti doi parametrii trimisi de catre frame
AS
DECLARE @msgEroare VARCHAR(8000), @utilizator VARCHAR(50), @idPrioritate INT
BEGIN TRY
    exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT -- output pentru ca variabilele sa poata sa fie modificate de procedura. In aceasta linie legam variabilele noastre declarate mai sus de variabilele folosite de procedura

    select @idPrioritate = @parXML.value('/row[1]/@idPrioritate', 'int') -- citim primul rand si id-ul
            
    DELETE FROM Prioritati WHERE idPrioritate=@idPrioritate
END TRY
BEGIN CATCH
    set @msgEroare=error_message() + '(' + OBJECT_NAME(@@procid) + ')' -- afisam eroarea pe care o prindem folosind error_message ca sa luam eroarea si luam id-ul procedurii apelate ca sa punem si numele ei in eroare
    RAISERROR (@msgEroare, 16, 1)
END CATCH

-- 3.1 Tickete - wIaTickete
GO
CREATE OR ALTER PROCEDURE wIaTickete @sesiune varchar(50), @parXML xml -- conventie pentru fiecare procedura: denumirea incepe cu w pentru web si are acesti doi parametrii trimisi de catre frame
AS
DECLARE @msgEroare VARCHAR(8000), @utilizator VARCHAR(50),
        @idTicket INT, @f_titlu VARCHAR(200), @f_idStare INT,
        @dataJos DATE, @dataSus DATE,
        @nrPagina INT, @nrItems INT, @nrTotal INT
BEGIN TRY
    exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT -- output pentru ca variabilele sa poata sa fie modificate de procedura. In aceasta linie legam variabilele noastre declarate mai sus de variabilele folosite de procedura

    -- paginare: frame-ul trimite pagina curenta (de la 0) si cate randuri incap pe pagina
    set @nrPagina = isnull(@parXML.value('(/row/@nrPagina)[1]', 'int'), 0)
    set @nrItems  = isnull(@parXML.value('(/row/@nrItemsPerPagina)[1]', 'int'), 100)

    -- filtrele trimise de frame; TRY_CONVERT ca sa nu crape daca vine text gol in loc de numar
    -- ATENTIE: numele atributelor din XQuery sunt case-sensitive si trebuie sa fie identice cu DataField-urile din webConfigFiltre.
    -- @datajos / @datasus sunt nume standard ASiS, scrise cu litere mici in toate machetele existente - nu le schimba.
    select @idTicket  = TRY_CONVERT(int, @parXML.value('(/row[1]/@idTicket)[1]', 'varchar(20)')), -- scris la fel ca in #tk mai jos, ca sa se potriveasca cu ce trimite inapoi macheta
           @f_titlu   = isnull(@parXML.value('(/row[1]/@f_titlu)[1]', 'varchar(200)'), ''),
           @f_idStare = TRY_CONVERT(int, @parXML.value('(/row[1]/@f_idStare)[1]', 'varchar(20)')), -- S mare, exact ca DataField1 din webConfigFiltre
           @dataJos   = @parXML.value('(/*/@datajos)[1]', 'date'), -- perioada trimisa de frame
           @dataSus   = @parXML.value('(/*/@datasus)[1]', 'date')

    IF object_id('tempdb..#tk') IS NOT NULL DROP TABLE #tk
    CREATE TABLE #tk (
        idTicket int, titlu nvarchar(200), descriere nvarchar(max),
        dataCreare date, dataRezolvare date,
        idCategorie int, categorie nvarchar(100), SLA_ore int,
        idPrioritate int, prioritate nvarchar(50), culoare varchar(7),
        idSolicitant varchar(6), solicitant varchar(50),
        idResponsabil varchar(6), responsabil varchar(50),
        idStare int, stare nvarchar(50), totalMinute int, row_nr int)

    INSERT INTO #tk
    SELECT t.idTicket, t.Titlu, t.Descriere,
           convert(date, t.DataCreare), convert(date, t.DataRezolvare),
           t.idCategorie, cat.Denumire, cat.SLA_ore,
           t.idPrioritate, pr.Denumire, pr.Culoare,
           rtrim(t.idSolicitant), rtrim(sol.Nume), -- rtrim pentru ca Marca si Nume sunt char, deci vin completate cu spatii pana la lungimea fixa
           rtrim(t.idResponsabil), rtrim(resp.Nume),
           t.Stare, st.Denumire,
           isnull((SELECT SUM(a.DurataMinute) FROM ActivitatiTicket a WHERE a.idTicket = t.idTicket), 0),
           row_number() over (order by t.idTicket desc)
    FROM   Tickete t
    JOIN   Categorii  cat ON cat.idCategorie  = t.idCategorie
    JOIN   Prioritati pr  ON pr.idPrioritate  = t.idPrioritate
    JOIN   Personal   sol ON sol.Marca        = t.idSolicitant
    LEFT   JOIN Personal resp ON resp.Marca   = t.idResponsabil -- LEFT pentru ca un ticket Nou nu are inca responsabil
    JOIN   StariTicket st ON st.idStare       = t.Stare
    WHERE (@f_titlu = '' OR t.Titlu LIKE '%' + @f_titlu + '%')
      AND (@f_idStare IS NULL OR t.Stare = @f_idStare)
      AND (@dataJos IS NULL OR t.DataCreare >= @dataJos)
      AND (@dataSus IS NULL OR t.DataCreare < dateadd(day, 1, @dataSus)) -- < ziua urmatoare ca sa prindem si orele din ziua @dataSus
      AND (@idTicket IS NULL OR t.idTicket = @idTicket)

    set @nrTotal = @@rowcount -- numarul total inainte de paginare; trebuie citit imediat dupa INSERT, altfel se pierde

    SELECT *, @nrTotal AS nrTotalItems
    FROM   #tk
    WHERE  row_nr BETWEEN @nrPagina*@nrItems+1 AND (@nrPagina+1)*@nrItems
    ORDER BY row_nr
    FOR XML RAW -- convertim in XML
END TRY
BEGIN CATCH
    set @msgEroare=error_message() + '(' + OBJECT_NAME(@@procid) + ')' -- afisam eroarea pe care o prindem folosind error_message ca sa luam eroarea si luam id-ul procedurii apelate ca sa punem si numele ei in eroare
    RAISERROR (@msgEroare, 16, 1)
END CATCH

-- 3.2 Tickete - wIaPozTickete (pozitiile machetei: activitatile raportate pe ticketul selectat in antet)
GO
CREATE OR ALTER PROCEDURE wIaPozTickete @sesiune varchar(50), @parXML xml -- conventie pentru fiecare procedura: denumirea incepe cu w pentru web si are acesti doi parametrii trimisi de catre frame
AS
DECLARE @msgEroare VARCHAR(8000), @utilizator VARCHAR(50), @idTicket INT
BEGIN TRY
    exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT -- output pentru ca variabilele sa poata sa fie modificate de procedura. In aceasta linie legam variabilele noastre declarate mai sus de variabilele folosite de procedura

    -- frame-ul trimite ticketul selectat in antet; numele atributului e case-sensitive si trebuie sa fie identic cu cel din wIaTickete
    select @idTicket = TRY_CONVERT(int, @parXML.value('(/row[1]/@idTicket)[1]', 'varchar(20)'))

    select t.idTicket                              AS idTicket, -- cheia, pentru refresh-ul antetului
           a.idActivitate                          AS idActivitate,
           convert(varchar, a.DataActivitate, 101) AS dataActivitate,
           rtrim(a.idResponsabil)                  AS idResponsabil, -- rtrim pentru ca Marca e char(6), deci vine completata cu spatii
           rtrim(pe.Nume)                          AS responsabil,   -- idem, Nume e char(50)
           a.TipActivitate                         AS tipActivitate,
           isnull(a.Descriere, '')                 AS descriere,     -- isnull pentru ca FOR XML RAW omite complet atributele NULL, iar macheta nu ar mai primi campul
           a.DurataMinute                          AS durataMin
    from   ActivitatiTicket a
    join   Tickete  t  ON t.idTicket = a.idTicket
    join   Personal pe ON pe.Marca   = a.idResponsabil
    where  a.idTicket = @idTicket
    order by a.DataActivitate, a.idActivitate
    FOR XML RAW -- convertim in XML
END TRY
BEGIN CATCH
    set @msgEroare=error_message() + '(' + OBJECT_NAME(@@procid) + ')' -- afisam eroarea pe care o prindem folosind error_message ca sa luam eroarea si luam id-ul procedurii apelate ca sa punem si numele ei in eroare
    RAISERROR (@msgEroare, 16, 1)
END CATCH

-- 3.3 Tickete - wScriuTickete
GO
CREATE OR ALTER PROCEDURE wScriuTickete @sesiune varchar(50), @parXML xml -- conventie pentru fiecare procedura: denumirea incepe cu w pentru web si are acesti doi parametrii trimisi de catre frame
AS
DECLARE @msgEroare VARCHAR(8000), @utilizator VARCHAR(50),
        @idTicket INT, @titlu NVARCHAR(200), @descriere NVARCHAR(MAX),
        @idCategorie INT, @idPrioritate INT, @idSolicitant CHAR(6),
        @idResponsabil CHAR(6), @update INT, @idStareNoua INT
BEGIN TRY
    exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT -- output pentru ca variabilele sa poata sa fie modificate de procedura. In aceasta linie legam variabilele noastre declarate mai sus de variabilele folosite de procedura

    -- numele atributelor sunt scrise identic cu cele emise de wIaTickete, pentru ca de acolo le primeste macheta si tot alea le trimite inapoi
    select @idTicket      = TRY_CONVERT(int, @parXML.value('(/row[1]/@idTicket)[1]', 'varchar(20)')),
           @titlu         = @parXML.value('(/row[1]/@titlu)[1]', 'nvarchar(200)'),
           @descriere     = @parXML.value('(/row[1]/@descriere)[1]', 'nvarchar(max)'),
           @idCategorie   = TRY_CONVERT(int, @parXML.value('(/row[1]/@idCategorie)[1]', 'varchar(20)')),
           @idPrioritate  = TRY_CONVERT(int, @parXML.value('(/row[1]/@idPrioritate)[1]', 'varchar(20)')),
           @idSolicitant  = nullif(rtrim(@parXML.value('(/row[1]/@idSolicitant)[1]', 'varchar(6)')), ''), -- Marca e char(6), nu numar; nullif ca sa tratam sirul gol trimis de macheta ca lipsa
           @idResponsabil = nullif(rtrim(@parXML.value('(/row[1]/@idResponsabil)[1]', 'varchar(6)')), ''),
           @update        = isnull(@parXML.value('(/row[1]/@update)[1]', 'bit'), 0)

    -- verificari de business
    IF len(isnull(@titlu, '')) = 0
        RAISERROR('Completati titlul ticketului!', 16, 1)
    IF @idCategorie IS NULL OR NOT EXISTS (SELECT 1 FROM Categorii WHERE idCategorie = @idCategorie)
        RAISERROR('Selectati o categorie valida!', 16, 1)
    IF @idPrioritate IS NULL OR NOT EXISTS (SELECT 1 FROM Prioritati WHERE idPrioritate = @idPrioritate)
        RAISERROR('Selectati o prioritate valida!', 16, 1)
    IF @idSolicitant IS NULL OR NOT EXISTS (SELECT 1 FROM Personal WHERE Marca = @idSolicitant)
        RAISERROR('Selectati un solicitant valid!', 16, 1)
    -- responsabilul e optional (ticketul Nou nu are inca unul), dar daca e completat trebuie sa existe in Personal
    IF @idResponsabil IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Personal WHERE Marca = @idResponsabil)
        RAISERROR('Responsabilul selectat nu exista in Personal!', 16, 1)

    IF @update = 0 -- ticket nou
    BEGIN
        select @idStareNoua = idStare FROM StariTicket WHERE Denumire = N'Nou'
        INSERT INTO Tickete (Titlu, Descriere, idCategorie, idPrioritate,
                             idSolicitant, idResponsabil, Stare) -- in Tickete coloana se numeste Stare, nu idStare; DataCreare se completeaza singura din DEFAULT
        VALUES (@titlu, @descriere, @idCategorie, @idPrioritate,
                @idSolicitant, @idResponsabil, @idStareNoua)
        set @idTicket = SCOPE_IDENTITY() -- retinem id-ul generat ca sa putem intoarce antetul reimprospatat mai jos
    END
    ELSE -- ticket pre-existent
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM Tickete WHERE idTicket = @idTicket)
            RAISERROR('Ticketul pe care incercati sa il modificati nu exista!', 16, 1)
        UPDATE Tickete
            SET Titlu = @titlu, Descriere = @descriere, idCategorie = @idCategorie,
                idPrioritate = @idPrioritate, idSolicitant = @idSolicitant,
                idResponsabil = @idResponsabil -- starea nu se modifica de aici, ci prin fluxul de stari (trigger-ul de jurnalizare)
        WHERE idTicket = @idTicket
    END

    -- intoarcem antetul reimprospatat, ca sa nu mai fie nevoie de inca un apel din frame
    set @parXML = (SELECT @idTicket AS idTicket FOR XML RAW) -- atributul trebuie scris exact cum il citeste wIaTickete
    exec wIaTickete @sesiune=@sesiune, @parXML=@parXML
END TRY
BEGIN CATCH
    set @msgEroare=error_message() + '(' + OBJECT_NAME(@@procid) + ')' -- afisam eroarea pe care o prindem folosind error_message ca sa luam eroarea si luam id-ul procedurii apelate ca sa punem si numele ei in eroare
    RAISERROR (@msgEroare, 16, 1)
END CATCH



-- 3.4 Tickete - wScriuPozTickete (o pozitie = o activitate raportata pe ticket)
-- Validarile cerute de B4 sunt facute aici, in procedura, nu doar prin trigger sau CHECK:
--   - nu se pot adauga/modifica activitati pe un ticket inchis
--   - DataActivitate nu poate fi inainte de DataCreare si nici in viitor
GO
CREATE OR ALTER PROCEDURE wScriuPozTickete @sesiune varchar(50), @parXML xml -- conventie pentru fiecare procedura: denumirea incepe cu w pentru web si are acesti doi parametrii trimisi de catre frame
AS
DECLARE @msgEroare VARCHAR(8000), @utilizator VARCHAR(50),
        @idTicket INT, @idActivitate INT, @c_data VARCHAR(20),
        @dataActivitate DATETIME, @idResponsabil CHAR(6),
        @tipActivitate NVARCHAR(30), @descriere NVARCHAR(500),
        @durataMin INT, @update INT,
        @dataCreare DATETIME, @tipStare VARCHAR(20)
BEGIN TRY
    exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT -- output pentru ca variabilele sa poata sa fie modificate de procedura. In aceasta linie legam variabilele noastre declarate mai sus de variabilele folosite de procedura

    -- antetul vine in /row[1], iar pozitia editata in /row[1]/row[1]; numele atributelor sunt scrise identic cu cele emise de wIaTickete si wIaPozTickete
    select @idTicket = TRY_CONVERT(int, @parXML.value('(/row[1]/@idTicket)[1]', 'varchar(20)'))

    select @idActivitate  = TRY_CONVERT(int, @parXML.value('(/row[1]/row[1]/@idActivitate)[1]', 'varchar(20)')),
           @c_data        = @parXML.value('(/row[1]/row[1]/@dataActivitate)[1]', 'varchar(20)'),
           @idResponsabil = nullif(rtrim(@parXML.value('(/row[1]/row[1]/@idResponsabil)[1]', 'varchar(6)')), ''), -- Marca e char(6), nu numar; nullif ca sa tratam sirul gol trimis de macheta ca lipsa
           @tipActivitate = @parXML.value('(/row[1]/row[1]/@tipActivitate)[1]', 'nvarchar(30)'),
           @descriere     = @parXML.value('(/row[1]/row[1]/@descriere)[1]', 'nvarchar(500)'),
           @durataMin     = TRY_CONVERT(int, @parXML.value('(/row[1]/row[1]/@durataMin)[1]', 'varchar(20)')),
           @update        = isnull(@parXML.value('(/row[1]/row[1]/@update)[1]', 'bit'), 0)

    set @dataActivitate = TRY_CONVERT(datetime, @c_data, 101) -- stilul 101 (mm/dd/yyyy), acelasi cu cel folosit de wIaPozTickete cand trimite data catre macheta

    -- ticketul pe care se adauga activitatea trebuie sa existe
    IF @idTicket IS NULL OR NOT EXISTS (SELECT 1 FROM Tickete WHERE idTicket = @idTicket)
        RAISERROR('Ticketul pentru care adaugati activitatea nu exista!', 16, 1)

    select @dataCreare = t.DataCreare, @tipStare = s.TipStare
    from   Tickete t JOIN StariTicket s ON s.idStare = t.Stare -- in Tickete coloana se numeste Stare, nu idStare
    where  t.idTicket = @idTicket

    -- B4: pe un ticket inchis nu se mai lucreaza
    IF @tipStare = 'inchis'
        RAISERROR('Ticketul este inchis - nu se mai pot adauga sau modifica activitati!', 16, 1)

    -- verificari de business pe campurile pozitiei
    IF @idResponsabil IS NULL OR NOT EXISTS (SELECT 1 FROM Personal WHERE Marca = @idResponsabil)
        RAISERROR('Selectati un responsabil valid pentru activitate!', 16, 1)
    IF @dataActivitate IS NULL
        RAISERROR('Completati data activitatii!', 16, 1)
    -- B4: comparatie pe ZI, nu pe moment exact - macheta trimite doar data, iar DataCreare are si ora,
    -- deci o activitate logata in aceeasi zi cu crearea ticketului trebuie sa fie valida
    IF CONVERT(date, @dataActivitate) < CONVERT(date, @dataCreare)
    BEGIN
        set @msgEroare = 'Data activitatii nu poate fi inaintea crearii ticketului ('
                       + convert(varchar, @dataCreare, 101) + ')!'
        RAISERROR(@msgEroare, 16, 1)
    END
    IF CONVERT(date, @dataActivitate) > CONVERT(date, GETDATE())
        RAISERROR('Data activitatii nu poate fi in viitor!', 16, 1)
    IF isnull(@durataMin, 0) <= 0
        RAISERROR('Durata (minute) trebuie sa fie un numar mai mare ca 0!', 16, 1)
    IF @tipActivitate NOT IN (N'diagnoza', N'interventie', N'comunicare')
        RAISERROR('Tip activitate invalid (diagnoza / interventie / comunicare)!', 16, 1)

    IF @update = 0 -- activitate noua
        INSERT INTO ActivitatiTicket (idTicket, idResponsabil, DataActivitate,
                                      DurataMinute, TipActivitate, Descriere)
        VALUES (@idTicket, @idResponsabil, @dataActivitate, @durataMin, @tipActivitate, @descriere)
    ELSE -- activitate pre-existenta
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM ActivitatiTicket
                       WHERE idActivitate = @idActivitate AND idTicket = @idTicket) -- si idTicket, ca sa nu se poata modifica o activitate de pe alt ticket
            RAISERROR('Activitatea pe care incercati sa o modificati nu exista pe acest ticket!', 16, 1)
        UPDATE ActivitatiTicket
            SET DataActivitate = @dataActivitate, idResponsabil = @idResponsabil,
                DurataMinute = @durataMin, TipActivitate = @tipActivitate, Descriere = @descriere
        WHERE idActivitate = @idActivitate
    END

    -- intoarcem pozitiile reimprospatate, ca sa nu mai fie nevoie de inca un apel din frame
    set @parXML = (SELECT @idTicket AS idTicket FOR XML RAW) -- atributul trebuie scris exact cum il citeste wIaPozTickete
    exec wIaPozTickete @sesiune=@sesiune, @parXML=@parXML
END TRY
BEGIN CATCH
    set @msgEroare=error_message() + '(' + OBJECT_NAME(@@procid) + ')' -- afisam eroarea pe care o prindem folosind error_message ca sa luam eroarea si luam id-ul procedurii apelate ca sa punem si numele ei in eroare
    RAISERROR (@msgEroare, 16, 1)
END CATCH

-- 3.5 Tickete - wStergTickete (sterge tot documentul: antet + pozitii + jurnal)
GO
CREATE OR ALTER PROCEDURE wStergTickete @sesiune varchar(50), @parXML xml -- conventie pentru fiecare procedura: denumirea incepe cu w pentru web si are acesti doi parametrii trimisi de catre frame
AS
DECLARE @msgEroare VARCHAR(8000), @utilizator VARCHAR(50), @idTicket INT
BEGIN TRY
    exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT -- output pentru ca variabilele sa poata sa fie modificate de procedura. In aceasta linie legam variabilele noastre declarate mai sus de variabilele folosite de procedura

    select @idTicket = TRY_CONVERT(int, @parXML.value('(/row[1]/@idTicket)[1]', 'varchar(20)')) -- scris la fel ca in wIaTickete, altfel nu regasim ticketul selectat

    IF @idTicket IS NULL
        RAISERROR('Selectati un ticket valid pentru stergere!', 16, 1)
    IF NOT EXISTS (SELECT 1 FROM Tickete WHERE idTicket = @idTicket)
        RAISERROR('Ticketul nu exista!', 16, 1)

    -- tranzactie pentru ca cele 3 stergeri sa fie totul-sau-nimic; altfel un ticket ar putea ramane fara jurnal sau invers
    BEGIN TRAN
        DELETE FROM ActivitatiTicket WHERE idTicket = @idTicket -- intai copiii, apoi parintele, altfel pica pe cheile straine
        DELETE FROM JurnalTickete    WHERE idTicket = @idTicket
        DELETE FROM Tickete          WHERE idTicket = @idTicket
    COMMIT TRAN
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRAN -- daca am apucat sa deschidem tranzactia, o anulam inainte sa aruncam eroarea
    set @msgEroare=error_message() + '(' + OBJECT_NAME(@@procid) + ')' -- afisam eroarea pe care o prindem folosind error_message ca sa luam eroarea si luam id-ul procedurii apelate ca sa punem si numele ei in eroare
    RAISERROR (@msgEroare, 16, 1)
END CATCH

-- 3.6 Tickete - wStergPozTickete (sterge o singura activitate de pe ticket)
-- B4: nu se pot sterge activitati de pe un ticket inchis
GO
CREATE OR ALTER PROCEDURE wStergPozTickete @sesiune varchar(50), @parXML xml -- conventie pentru fiecare procedura: denumirea incepe cu w pentru web si are acesti doi parametrii trimisi de catre frame
AS
DECLARE @msgEroare VARCHAR(8000), @utilizator VARCHAR(50),
        @idActivitate INT, @idTicket INT, @tipStare VARCHAR(20)
BEGIN TRY
    exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT -- output pentru ca variabilele sa poata sa fie modificate de procedura. In aceasta linie legam variabilele noastre declarate mai sus de variabilele folosite de procedura

    select @idActivitate = TRY_CONVERT(int, @parXML.value('(/row[1]/@idActivitate)[1]', 'varchar(20)')) -- scris la fel ca in wIaPozTickete

    IF @idActivitate IS NULL
        RAISERROR('Selectati o activitate valida pentru stergere!', 16, 1)

    -- aflam pe ce ticket sta activitatea si in ce stare e ticketul; @idTicket ne trebuie si pentru refresh-ul de la final
    select @idTicket = a.idTicket, @tipStare = s.TipStare
    from   ActivitatiTicket a
    join   Tickete t     ON t.idTicket = a.idTicket
    join   StariTicket s ON s.idStare  = t.Stare -- in Tickete coloana se numeste Stare, nu idStare
    where  a.idActivitate = @idActivitate

    IF @idTicket IS NULL -- ramane NULL daca select-ul de mai sus n-a gasit niciun rand
        RAISERROR('Activitatea nu exista!', 16, 1)
    IF @tipStare = 'inchis'
        RAISERROR('Ticketul este inchis - nu se mai pot sterge activitati!', 16, 1)

    DELETE FROM ActivitatiTicket WHERE idActivitate = @idActivitate

    -- intoarcem pozitiile ramase, ca sa nu mai fie nevoie de inca un apel din frame
    set @parXML = (SELECT @idTicket AS idTicket FOR XML RAW) -- atributul trebuie scris exact cum il citeste wIaPozTickete
    exec wIaPozTickete @sesiune=@sesiune, @parXML=@parXML
END TRY
BEGIN CATCH
    set @msgEroare=error_message() + '(' + OBJECT_NAME(@@procid) + ')' -- afisam eroarea pe care o prindem folosind error_message ca sa luam eroarea si luam id-ul procedurii apelate ca sa punem si numele ei in eroare
    RAISERROR (@msgEroare, 16, 1)
END CATCH

-- 3.7 Tickete - wIaJurnalTickete (istoricul schimbarilor de stare pe ticketul selectat)
GO
CREATE OR ALTER PROCEDURE wIaJurnalTickete @sesiune varchar(50), @parXML xml -- conventie pentru fiecare procedura: denumirea incepe cu w pentru web si are acesti doi parametrii trimisi de catre frame
AS
DECLARE @msgEroare VARCHAR(8000), @utilizator VARCHAR(50), @idTicket INT
BEGIN TRY
    exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT -- output pentru ca variabilele sa poata sa fie modificate de procedura. In aceasta linie legam variabilele noastre declarate mai sus de variabilele folosite de procedura

    -- ca la pozitii, ticketul vine ca atribut pe randul de antet; scris la fel ca in wIaTickete
    select @idTicket = TRY_CONVERT(int, @parXML.value('(/row[1]/@idTicket)[1]', 'varchar(20)'))

    select j.idTicket                                  AS idTicket,       -- cheia de legatura cu antetul
           j.idJurnal                                  AS idJurnal,       -- cheia randului
           convert(varchar, j.DataModificare, 101)     AS dataModificare, -- stilul 101, acelasi ca in wIaPozTickete
           convert(varchar(5), j.DataModificare, 108)  AS oraModificare,  -- stilul 108 = hh:mi:ss, taiat la hh:mi
           s.Denumire                                  AS stare,
           s.TipStare                                  AS tipStare,
           j.Utilizator                                AS utilizator,
           isnull(j.Comentariu, '')                    AS comentariu      -- isnull pentru ca FOR XML RAW omite complet atributele NULL, iar macheta nu ar mai primi campul
    from   JurnalTickete j
    join   StariTicket   s ON s.idStare = j.Stare -- in JurnalTickete coloana se numeste Stare, nu idStare
    where  j.idTicket = @idTicket
    order by j.DataModificare, j.idJurnal
    FOR XML RAW -- convertim in XML
END TRY
BEGIN CATCH
    set @msgEroare=error_message() + '(' + OBJECT_NAME(@@procid) + ')' -- afisam eroarea pe care o prindem folosind error_message ca sa luam eroarea si luam id-ul procedurii apelate ca sa punem si numele ei in eroare
    RAISERROR (@msgEroare, 16, 1)
END CATCH

-- 4. Autocomplete (listele de selectie din machete)
-- Conventia ASiS: numele incepe cu wAC, iar procedura intoarce coloanele
-- cod / denumire / info (optional si culoare), pe care frame-ul le afiseaza in lista.
-- Parametrul de cautare se numeste searchText - asa il trimite frame-ul in toate machetele.

-- 4.1 wACCategoriiHelpdesk
-- ATENTIE: numele nu e wACCategorii pentru ca acela e deja luat de o procedura ASiS
-- a modulului TB, care lucreaza pe alta tabela Categorii (cod_categ / denumire_categ).
GO
CREATE OR ALTER PROCEDURE wACCategoriiHelpdesk @sesiune varchar(50), @parXML xml -- conventie pentru fiecare procedura: denumirea incepe cu w pentru web si are acesti doi parametrii trimisi de catre frame
AS
DECLARE @msgEroare VARCHAR(8000), @utilizator VARCHAR(50), @searchText VARCHAR(100)
BEGIN TRY
    exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT -- output pentru ca variabilele sa poata sa fie modificate de procedura. In aceasta linie legam variabilele noastre declarate mai sus de variabilele folosite de procedura

    -- spatiile devin %, ca sa functioneze si cautarea dupa mai multe cuvinte ("cont email" gaseste "Cont de email")
    set @searchText = replace(isnull(@parXML.value('(/row[1]/@searchText)[1]', 'varchar(100)'), ''), ' ', '%')

    select c.idCategorie                                  AS cod,      -- valoarea salvata in ticket
           c.Denumire                                     AS denumire, -- textul afisat in lista
           'SLA ' + cast(c.SLA_ore AS varchar(10)) + 'h'  AS info      -- randul secundar din lista
    from   Categorii c
    where  c.Denumire LIKE '%' + @searchText + '%'
        OR c.Descriere LIKE '%' + @searchText + '%' -- cautam si in descriere, ca sa gaseasca "parola" la categoria Acces
    order by c.Denumire
    FOR XML RAW -- convertim in XML
END TRY
BEGIN CATCH
    set @msgEroare=error_message() + '(' + OBJECT_NAME(@@procid) + ')' -- afisam eroarea pe care o prindem folosind error_message ca sa luam eroarea si luam id-ul procedurii apelate ca sa punem si numele ei in eroare
    RAISERROR (@msgEroare, 16, 1)
END CATCH

-- 4.2 wACPrioritati
GO
CREATE OR ALTER PROCEDURE wACPrioritati @sesiune varchar(50), @parXML xml -- conventie pentru fiecare procedura: denumirea incepe cu w pentru web si are acesti doi parametrii trimisi de catre frame
AS
DECLARE @msgEroare VARCHAR(8000), @utilizator VARCHAR(50), @searchText VARCHAR(100)
BEGIN TRY
    exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT -- output pentru ca variabilele sa poata sa fie modificate de procedura. In aceasta linie legam variabilele noastre declarate mai sus de variabilele folosite de procedura

    set @searchText = replace(isnull(@parXML.value('(/row[1]/@searchText)[1]', 'varchar(100)'), ''), ' ', '%')

    select p.idPrioritate                       AS cod,
           p.Denumire                           AS denumire,
           'Nivel ' + cast(p.Nivel AS varchar(2)) AS info,
           isnull(p.Culoare, '#000000')         AS culoare -- frame-ul coloreaza randul din lista cu valoarea asta
    from   Prioritati p
    where  p.Denumire LIKE '%' + @searchText + '%'
    order by p.Nivel -- 1 = critic apare primul, nu alfabetic
    FOR XML RAW -- convertim in XML
END TRY
BEGIN CATCH
    set @msgEroare=error_message() + '(' + OBJECT_NAME(@@procid) + ')' -- afisam eroarea pe care o prindem folosind error_message ca sa luam eroarea si luam id-ul procedurii apelate ca sa punem si numele ei in eroare
    RAISERROR (@msgEroare, 16, 1)
END CATCH

-- 4.3 wACSolicitant (solicitantul ticketului: orice angajat)
-- Personal nu are Departament sau Email, asa ca info se compune din functie si locul de munca,
-- exact ca in wACPersonal, procedura ASiS standard din baza.
GO
CREATE OR ALTER PROCEDURE wACSolicitant @sesiune varchar(50), @parXML xml -- conventie pentru fiecare procedura: denumirea incepe cu w pentru web si are acesti doi parametrii trimisi de catre frame
AS
DECLARE @msgEroare VARCHAR(8000), @utilizator VARCHAR(50), @searchText VARCHAR(100)
BEGIN TRY
    exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT -- output pentru ca variabilele sa poata sa fie modificate de procedura. In aceasta linie legam variabilele noastre declarate mai sus de variabilele folosite de procedura

    set @searchText = replace(isnull(@parXML.value('(/row[1]/@searchText)[1]', 'varchar(100)'), ''), ' ', '%')

    select top 100 rtrim(p.Marca)                                       AS cod,      -- cheia din Personal e Marca (char(6)), nu un id numeric
           rtrim(p.Nume)                                                AS denumire, -- rtrim pentru ca Nume e char(50) si vine completat cu spatii
           rtrim(isnull(f.Denumire, 'Functie nedefinita'))
             + ' - Lm. ' + rtrim(p.Loc_de_munca)                        AS info
    from   Personal p
    left   join functii f ON f.Cod_functie = p.Cod_functie
    where (rtrim(p.Nume) LIKE '%' + @searchText + '%'
        OR rtrim(p.Marca) LIKE @searchText + '%'          -- cautare si dupa marca, daca utilizatorul o stie
        OR f.Denumire LIKE '%' + @searchText + '%')
      and  rtrim(p.Nume) NOT LIKE '%test%'                -- scoatem inregistrarile de proba din Personal, ca sa nu apara in lista
      and  rtrim(p.Nume) LIKE '% %'                       -- pastram doar intrarile care au nume si prenume
    order by rtrim(p.Nume)
    FOR XML RAW -- convertim in XML
END TRY
BEGIN CATCH
    set @msgEroare=error_message() + '(' + OBJECT_NAME(@@procid) + ')' -- afisam eroarea pe care o prindem folosind error_message ca sa luam eroarea si luam id-ul procedurii apelate ca sa punem si numele ei in eroare
    RAISERROR (@msgEroare, 16, 1)
END CATCH

-- 4.4 wACResponsabil (responsabilul ticketului: doar personal IT)
-- Personal nu are o coloana EsteIT, asa ca IT-ul se identifica dupa functie.
-- Daca vrei alt criteriu (loc de munca, o lista fixa de marci), se schimba doar filtrul de mai jos.
GO
CREATE OR ALTER PROCEDURE wACResponsabil @sesiune varchar(50), @parXML xml -- conventie pentru fiecare procedura: denumirea incepe cu w pentru web si are acesti doi parametrii trimisi de catre frame
AS
DECLARE @msgEroare VARCHAR(8000), @utilizator VARCHAR(50), @searchText VARCHAR(100)
BEGIN TRY
    exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT -- output pentru ca variabilele sa poata sa fie modificate de procedura. In aceasta linie legam variabilele noastre declarate mai sus de variabilele folosite de procedura

    set @searchText = replace(isnull(@parXML.value('(/row[1]/@searchText)[1]', 'varchar(100)'), ''), ' ', '%')

    select top 100 rtrim(p.Marca)                                       AS cod,
           rtrim(p.Nume)                                                AS denumire,
           rtrim(f.Denumire) + ' - Lm. ' + rtrim(p.Loc_de_munca)        AS info
    from   Personal p
    join   functii f ON f.Cod_functie = p.Cod_functie -- JOIN simplu, nu LEFT: cine n-are functie definita nu poate fi din IT
    where  rtrim(f.Denumire) IN ('PROGRAMATOR', 'ANALIST', 'Informatician') -- aici se schimba criteriul de "e din IT"
      and (rtrim(p.Nume) LIKE '%' + @searchText + '%'
        OR rtrim(p.Marca) LIKE @searchText + '%')
      and  rtrim(p.Nume) NOT LIKE '%test%'
      and  rtrim(p.Nume) LIKE '% %'
    order by rtrim(p.Nume)
    FOR XML RAW -- convertim in XML
END TRY
BEGIN CATCH
    set @msgEroare=error_message() + '(' + OBJECT_NAME(@@procid) + ')' -- afisam eroarea pe care o prindem folosind error_message ca sa luam eroarea si luam id-ul procedurii apelate ca sa punem si numele ei in eroare
    RAISERROR (@msgEroare, 16, 1)
END CATCH

-- 4.5 wACStariTicket (starile ticketului, pentru filtrul din lista si pentru parametrul raportului B7)
GO
CREATE OR ALTER PROCEDURE wACStariTicket @sesiune varchar(50), @parXML xml -- conventie pentru fiecare procedura: denumirea incepe cu w pentru web si are acesti doi parametrii trimisi de catre frame
AS
DECLARE @msgEroare VARCHAR(8000), @utilizator VARCHAR(50), @searchText VARCHAR(100)
BEGIN TRY
    exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT -- output pentru ca variabilele sa poata sa fie modificate de procedura. In aceasta linie legam variabilele noastre declarate mai sus de variabilele folosite de procedura

    set @searchText = replace(isnull(@parXML.value('(/row[1]/@searchText)[1]', 'varchar(100)'), ''), ' ', '%')

    select s.idStare    AS cod,
           s.Denumire   AS denumire,
           s.TipStare   AS info
    from   StariTicket s
    where  s.Denumire LIKE '%' + @searchText + '%'
        OR s.TipStare LIKE '%' + @searchText + '%' -- cautam si dupa tip, ca "inchis" sa gaseasca starea chiar daca scrii tipul
    order by s.Ordine -- ordinea fluxului: Nou, Atribuit, In lucru, Rezolvat, Inchis - nu alfabetic
    FOR XML RAW -- convertim in XML
END TRY
BEGIN CATCH
    set @msgEroare=error_message() + '(' + OBJECT_NAME(@@procid) + ')' -- afisam eroarea pe care o prindem folosind error_message ca sa luam eroarea si luam id-ul procedurii apelate ca sa punem si numele ei in eroare
    RAISERROR (@msgEroare, 16, 1)
END CATCH

-- 5. Export Excel
-- Conventia ASiS: procedura construieste doua bucati de XML - definitia coloanelor si datele -
-- le impacheteaza intr-un singur @px si il preda lui GenExcelsauVizualizare, care face fisierul.

-- 5.1 wOPExportTicketeExcel
-- Foloseste exact aceleasi filtre ca wIaTickete, ca exportul sa contina fix ce vede utilizatorul in lista.
GO
CREATE OR ALTER PROCEDURE wOPExportTicketeExcel @sesiune varchar(50), @parXML xml -- conventie pentru fiecare procedura: denumirea incepe cu w pentru web si are acesti doi parametrii trimisi de catre frame
AS
BEGIN TRY
    DECLARE @msgEroare VARCHAR(1000), @utilizator VARCHAR(50), @px XML,
            @f_titlu VARCHAR(200), @f_idStare INT, @dataJos DATE, @dataSus DATE, @actiune VARCHAR(2)

    -- aceleasi nume de atribute ca in wIaTickete, ca filtrele din machetă sa se aplice si la export
    select @f_titlu   = replace(isnull(@parXML.value('(/*/@f_titlu)[1]', 'varchar(200)'), ''), ' ', '%'),
           @f_idStare = TRY_CONVERT(int, @parXML.value('(/*/@f_idStare)[1]', 'varchar(20)')), -- S mare, la fel ca in wIaTickete si in webConfigFiltre
           @dataJos   = @parXML.value('(/*/@datajos)[1]', 'date'),
           @dataSus   = @parXML.value('(/*/@datasus)[1]', 'date'),
           @actiune   = isnull(@parXML.value('(/*/@actiune)[1]', 'varchar(2)'), 'E') -- E = export in fisier, V = vizualizare

    exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT -- output pentru ca variabilele sa poata sa fie modificate de procedura

    IF object_id('tempdb..#tkExport') IS NOT NULL DROP TABLE #tkExport
    CREATE TABLE #tkExport (
        idTicket int, titlu varchar(200), categorie varchar(100), prioritate varchar(50),
        solicitant varchar(50), responsabil varchar(50), stare varchar(50),
        dataCreare varchar(10), dataRezolvare varchar(10),
        oreRezolvare decimal(15,2), SLA_ore int, inTermen varchar(2), minuteLucrate int,
        dataSortare datetime) -- coloana ajutatoare doar pentru ORDER BY, nu se exporta

    INSERT INTO #tkExport (idTicket, titlu, categorie, prioritate, solicitant, responsabil, stare,
                           dataCreare, dataRezolvare, oreRezolvare, SLA_ore, inTermen, minuteLucrate, dataSortare)
    SELECT t.idTicket,
           rtrim(t.Titlu),
           rtrim(cat.Denumire),
           rtrim(pr.Denumire),
           rtrim(sol.Nume),                                    -- rtrim pentru ca Nume e char(50) si vine cu spatii
           isnull(rtrim(resp.Nume), ''),                       -- ticketele Noi nu au responsabil
           rtrim(st.Denumire),
           convert(varchar(10), t.DataCreare, 103),            -- 103 = dd/mm/yyyy, formatul citit de om in Excel
           isnull(convert(varchar(10), t.DataRezolvare, 103), ''),
           convert(decimal(15,2), datediff(MINUTE, t.DataCreare, t.DataRezolvare) / 60.0),
           cat.SLA_ore,
           CASE WHEN t.DataRezolvare IS NULL THEN ''           -- inca nerezolvat, nu se poate spune
                WHEN datediff(MINUTE, t.DataCreare, t.DataRezolvare) / 60.0 <= cat.SLA_ore THEN 'DA'
                ELSE 'NU' END,
           isnull((SELECT SUM(a.DurataMinute) FROM ActivitatiTicket a WHERE a.idTicket = t.idTicket), 0),
           t.DataCreare
    FROM   Tickete t
    JOIN   Categorii  cat ON cat.idCategorie  = t.idCategorie
    JOIN   Prioritati pr  ON pr.idPrioritate  = t.idPrioritate
    JOIN   Personal   sol ON sol.Marca        = t.idSolicitant
    LEFT   JOIN Personal resp ON resp.Marca   = t.idResponsabil
    JOIN   StariTicket st ON st.idStare       = t.Stare -- in Tickete coloana se numeste Stare, nu idStare
    WHERE (@f_titlu = '' OR t.Titlu LIKE '%' + @f_titlu + '%')
      AND (@f_idStare IS NULL OR t.Stare = @f_idStare)
      AND (@dataJos IS NULL OR t.DataCreare >= @dataJos)
      AND (@dataSus IS NULL OR t.DataCreare < dateadd(day, 1, @dataSus))

    -- definitia coloanelor: numecol = numele din #tkExport, dencol = antetul din Excel, tipcol = C text / N numeric
    CREATE TABLE #coloaneExcel (dencol varchar(200), numecol varchar(200), tipcol varchar(10), _format varchar(20))
    INSERT INTO #coloaneExcel (numecol, dencol, tipcol, _format)
    VALUES
    ('idTicket',      'Nr. ticket',        'N', NULL),
    ('titlu',         'Titlu',             'C', NULL),
    ('categorie',     'Categorie',         'C', NULL),
    ('prioritate',    'Prioritate',        'C', NULL),
    ('solicitant',    'Solicitant',        'C', NULL),
    ('responsabil',   'Responsabil',       'C', NULL),
    ('stare',         'Stare',             'C', NULL),
    ('dataCreare',    'Data creare',       'C', NULL),
    ('dataRezolvare', 'Data rezolvare',    'C', NULL),
    ('oreRezolvare',  'Ore pana la rezolvare', 'N', NULL),
    ('SLA_ore',       'SLA (ore)',         'N', NULL),
    ('inTermen',      'In termen',         'C', NULL),
    ('minuteLucrate', 'Minute lucrate',    'N', NULL)

    set @px = (
        select 'SituatieTickete' as numeFisier, @actiune actiune,
            (select * from #coloaneExcel for xml raw, type) coloane,
            (select idTicket, titlu, categorie, prioritate, solicitant, responsabil, stare,
                    dataCreare, dataRezolvare, oreRezolvare, SLA_ore, inTermen, minuteLucrate
             from #tkExport
             order by dataSortare desc -- cele mai noi tickete primele; coloana de sortare nu apare in export
             for xml raw, type) date,
            (select 'Tickete' numeSheet,
                16 _font_dim, 'bold' as _font_atribut -- atribute pentru capul de tabel
            for xml raw, type) info
        for xml raw ('row'))

    exec GenExcelsauVizualizare @sesiune=@sesiune, @parXML=@px
END TRY
BEGIN CATCH
    set @msgEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@procid) + ')'
    RAISERROR (@msgEroare, 16, 1)
END CATCH
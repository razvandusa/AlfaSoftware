-- =============================
-- | B2: Populare date de test |
-- =============================

-- 1. CATEGORII (cu SLA in ore)
INSERT INTO Categorii (Denumire, Descriere, SLA_ore) VALUES
    (N'Hardware',  N'Defectiuni echipamente: PC, laptop, imprimante',   24),
    (N'Software',  N'Probleme aplicatii, licente, instalari',            16),
    (N'Acces',     N'Cereri de acces, resetari parola, permisiuni',       8),
    (N'Retea',     N'Conectivitate, VPN, internet, wireless',             4),
    (N'Email',     N'Cont email, spam, casuta plina',                    12);

-- 2. PRIORITATI (Nivel 1=critic ... 4=scazut)
INSERT INTO Prioritati (Denumire, Nivel, Culoare) VALUES
    (N'Critic',  1, '#D32F2F'),
    (N'Urgent',  2, '#F57C00'),
    (N'Normal',  3, '#1976D2'),
    (N'Scazut',  4, '#388E3C');

-- 3. STARI TICKET (fluxul complet)
INSERT INTO StariTicket (Denumire, Ordine, TipStare) VALUES
    (N'Nou',        1, 'deschis'),
    (N'Atribuit',   2, 'deschis'),
    (N'In lucru',   3, 'in_lucru'),
    (N'Rezolvat',   4, 'in_lucru'),
    (N'Inchis',     5, 'inchis');

-- 4. TICKETE
DECLARE @t1 INT, @t2 INT, @t3 INT, @t4 INT, @t5 INT;

    -- 4.1 Ticket 1: NOU, fara responsabil inca
    INSERT INTO Tickete (Titlu, Descriere, idCategorie, idPrioritate, idSolicitant, idResponsabil, DataCreare, Stare)
    VALUES (N'Laptopul nu porneste', N'Ecran negru dupa update', 1, 2, '831', NULL, '2026-07-20T08:30:00', 1);
    SET @t1 = SCOPE_IDENTITY();

    -- 4.2 Ticket 2: ATRIBUIT
    INSERT INTO Tickete (Titlu, Descriere, idCategorie, idPrioritate, idSolicitant, idResponsabil, DataCreare, Stare)
    VALUES (N'Nu pot accesa VPN-ul', N'Eroare la conectare FortiClient', 4, 1, '852', '856', '2026-07-21T09:15:00', 2);
    SET @t2 = SCOPE_IDENTITY();

    -- 4.3 Ticket 3: IN LUCRU
    INSERT INTO Tickete (Titlu, Descriere, idCategorie, idPrioritate, idSolicitant, idResponsabil, DataCreare, Stare)
    VALUES (N'Resetare parola cont AD', N'Cont blocat dupa 3 incercari', 3, 3, '3773', '11111', '2026-07-22T10:00:00', 3);
    SET @t3 = SCOPE_IDENTITY();

    -- 4.4 Ticket 4: REZOLVAT (are DataRezolvare)
    INSERT INTO Tickete (Titlu, Descriere, idCategorie, idPrioritate, idSolicitant, idResponsabil, DataCreare, DataRezolvare, Stare)
    VALUES (N'Instalare Office', N'Licenta Microsoft 365 lipsa', 2, 3, '831', '856', '2026-07-19T11:00:00', '2026-07-19T15:30:00', 4);
    SET @t4 = SCOPE_IDENTITY();

    -- 4.5 Ticket 5: INCHIS (ciclu complet)
    INSERT INTO Tickete (Titlu, Descriere, idCategorie, idPrioritate, idSolicitant, idResponsabil, DataCreare, DataRezolvare, Stare)
    VALUES (N'Casuta email plina', N'Nu mai pot primi mesaje', 5, 4, '852', '11111', '2026-07-15T13:00:00', '2026-07-16T09:00:00', 5);
    SET @t5 = SCOPE_IDENTITY();

-- 5. JURNAL: istoricul schimbarilor de stare
INSERT INTO JurnalTickete (idTicket, Stare, DataModificare, Utilizator, Comentariu) VALUES
    -- 5.1 Ticket 1: doar Nou
    (@t1, 1, '2026-07-20T08:30:00', N'831',   N'Ticket creat'),
    -- 5.2 Ticket 2: Nou -> Atribuit
    (@t2, 1, '2026-07-21T09:15:00', N'852',   N'Ticket creat'),
    (@t2, 2, '2026-07-21T09:40:00', N'856',   N'Atribuit catre IT'),
    -- 5.3 Ticket 3: Nou -> Atribuit -> In lucru
    (@t3, 1, '2026-07-22T10:00:00', N'3773',  N'Ticket creat'),
    (@t3, 2, '2026-07-22T10:20:00', N'11111', N'Preluat de IT'),
    (@t3, 3, '2026-07-22T10:45:00', N'11111', N'Investigare in curs'),
    -- 5.4 Ticket 4: Nou -> Atribuit -> In lucru -> Rezolvat
    (@t4, 1, '2026-07-19T11:00:00', N'831',   N'Ticket creat'),
    (@t4, 2, '2026-07-19T11:30:00', N'856',   N'Atribuit'),
    (@t4, 3, '2026-07-19T13:00:00', N'856',   N'Instalare pornita'),
    (@t4, 4, '2026-07-19T15:30:00', N'856',   N'Office instalat cu succes'),
    -- 5.5 Ticket 5: ciclu complet Nou -> ... -> Inchis
    (@t5, 1, '2026-07-15T13:00:00', N'852',   N'Ticket creat'),
    (@t5, 2, '2026-07-15T13:20:00', N'11111', N'Atribuit'),
    (@t5, 3, '2026-07-15T14:00:00', N'11111', N'Curatare casuta'),
    (@t5, 4, '2026-07-16T09:00:00', N'11111', N'Spatiu eliberat'),
    (@t5, 5, '2026-07-16T09:30:00', N'11111', N'Confirmat de utilizator, inchis');

-- 6. ACTIVITATI: munca efectiva raportata de responsabili
INSERT INTO ActivitatiTicket (idTicket, idResponsabil, DataActivitate, DurataMinute, TipActivitate, Descriere) VALUES
    (@t3, '11111', '2026-07-22T10:45:00', 20, 'diagnoza',    N'Verificare cont in Active Directory'),
    (@t3, '11111', '2026-07-22T11:10:00', 15, 'interventie', N'Deblocare cont si resetare parola'),
    (@t4, '856',   '2026-07-19T13:00:00', 45, 'interventie', N'Instalare pachet Office 365'),
    (@t4, '856',   '2026-07-19T14:00:00', 10, 'comunicare',  N'Confirmare cu utilizatorul'),
    (@t5, '11111', '2026-07-15T14:00:00', 30, 'diagnoza',    N'Analiza spatiu casuta'),
    (@t5, '11111', '2026-07-15T14:40:00', 25, 'interventie', N'Arhivare mesaje vechi'),
    (@t5, '11111', '2026-07-16T09:00:00', 10, 'comunicare',  N'Informare utilizator');
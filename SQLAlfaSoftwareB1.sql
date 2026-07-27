GO
USE Student8

-- ===============================
-- | B1: Structura bazei de date |
-- ===============================

-- 1. CATEGORII (Tipul problemei: hardware, software, acces, retea etc. + SLA)
CREATE TABLE Categorii (
    idCategorie   INT IDENTITY(1,1) PRIMARY KEY,
    Denumire      NVARCHAR(100)  NOT NULL,
    Descriere     NVARCHAR(400)  NULL,
    SLA_ore       INT            NOT NULL
        CONSTRAINT CK_Categorii_SLA CHECK (SLA_ore > 0)
);

-- 2. PRIORITATI (Nivel 1=critic ... 4=scazut)
CREATE TABLE Prioritati (
    idPrioritate  INT IDENTITY(1,1) PRIMARY KEY,
    Denumire      NVARCHAR(50)   NOT NULL,
    Nivel         TINYINT        NOT NULL
        CONSTRAINT CK_Prioritati_Nivel CHECK (Nivel BETWEEN 1 AND 4),
    Culoare       VARCHAR(7)     NULL   -- ex. '#FF0000'
);

-- 3. STARI TICKET (Fluxul starilor: Nou -> Atribuit -> In lucru -> Rezolvat -> Inchis)
CREATE TABLE StariTicket (
    idStare       INT IDENTITY(1,1) PRIMARY KEY,
    Denumire      NVARCHAR(50)   NOT NULL,
    Ordine        TINYINT        NOT NULL,
    TipStare      VARCHAR(20)    NOT NULL
        CONSTRAINT CK_StariTicket_Tip CHECK (TipStare IN ('deschis','in_lucru','inchis'))
);

-- 4. TICKETE (Documentul central: cerere/problema raportata de un solicitant, atribuita unui responsabil IT)
CREATE TABLE Tickete (
    idTicket       INT IDENTITY(1,1) PRIMARY KEY,
    Titlu          NVARCHAR(200)  NOT NULL,
    Descriere      NVARCHAR(MAX)  NULL,
    idCategorie    INT            NOT NULL,
    idPrioritate   INT            NOT NULL,
    idSolicitant   CHAR(6)        NOT NULL,
    idResponsabil  CHAR(6)        NULL,   -- NULL cat timp ticketul e Nou
    DataCreare     DATETIME       NOT NULL
        CONSTRAINT DF_Tickete_DataCreare DEFAULT (GETDATE()),
    DataRezolvare  DATETIME       NULL,   -- se completeaza la trecerea in 'Rezolvat'
    Stare          INT            NOT NULL,
    Detalii        XML            NULL,

    CONSTRAINT FK_Tickete_Categorie
        FOREIGN KEY (idCategorie)   REFERENCES Categorii(idCategorie),
    CONSTRAINT FK_Tickete_Prioritate
        FOREIGN KEY (idPrioritate)  REFERENCES Prioritati(idPrioritate),
    CONSTRAINT FK_Tickete_Stare
        FOREIGN KEY (Stare)         REFERENCES StariTicket(idStare),
    CONSTRAINT FK_Tickete_Solicitant
        FOREIGN KEY (idSolicitant)  REFERENCES Personal(Marca),
    CONSTRAINT FK_Tickete_Responsabil
        FOREIGN KEY (idResponsabil) REFERENCES Personal(Marca)
);

-- 5. JURNAL TICKETE (Istoricul schimbarilor de stare: cine, cand si de ce - trasabilitate completa)
CREATE TABLE JurnalTickete (
    idJurnal       INT IDENTITY(1,1) PRIMARY KEY,
    idTicket       INT            NOT NULL,
    Stare          INT            NOT NULL,
    DataModificare DATETIME       NOT NULL
        CONSTRAINT DF_Jurnal_Data DEFAULT (GETDATE()),
    Utilizator     NVARCHAR(100)  NOT NULL,
    Comentariu     NVARCHAR(500)  NULL,

    CONSTRAINT FK_Jurnal_Ticket
        FOREIGN KEY (idTicket) REFERENCES Tickete(idTicket),
    CONSTRAINT FK_Jurnal_Stare
        FOREIGN KEY (Stare)    REFERENCES StariTicket(idStare)
);

-- 6. ACTIVITATI TICKET (Munca efectiva raportata de responsabil: timp real lucrat, distinct de timpul calendaristic)
CREATE TABLE ActivitatiTicket (
    idActivitate   INT IDENTITY(1,1) PRIMARY KEY,
    idTicket       INT            NOT NULL,
    idResponsabil  CHAR(6)        NOT NULL,
    DataActivitate DATETIME       NOT NULL
        CONSTRAINT DF_Activitati_Data DEFAULT (GETDATE()),
    DurataMinute   INT            NOT NULL
        CONSTRAINT CK_Activitati_Durata CHECK (DurataMinute > 0),
    TipActivitate  NVARCHAR(30)   NOT NULL
        CONSTRAINT CK_Activitati_Tip
        CHECK (TipActivitate IN ('diagnoza', 'interventie', 'comunicare')),
    Descriere      NVARCHAR(500)  NULL,

    CONSTRAINT FK_Activitati_Ticket
        FOREIGN KEY (idTicket)      REFERENCES Tickete(idTicket),
    CONSTRAINT FK_Activitati_Responsabil
        FOREIGN KEY (idResponsabil) REFERENCES Personal(Marca)
);
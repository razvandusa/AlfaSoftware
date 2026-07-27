-- =======================================
-- | B5: Scripturi SQL pentru indicatori |
-- =======================================

-- 1. Tickete deschise pe categorie si prioritate
GO
CREATE OR ALTER VIEW vw_TicheteDeschise AS
    SELECT
        c.Denumire            AS Categorie,
        pr.Denumire           AS Prioritate,
        pr.Nivel,
        COUNT(t.idTicket)     AS NrTicheteDeschise
    FROM Tickete t
    JOIN Categorii c      ON c.idCategorie  = t.idCategorie
    JOIN Prioritati pr    ON pr.idPrioritate = t.idPrioritate
    JOIN StariTicket s    ON s.idStare = t.Stare
    WHERE s.TipStare <> 'inchis'
    GROUP BY c.Denumire, pr.Denumire, pr.Nivel;
GO

-- 2a. Timpul mediu de rezolvare pe categorie in ore
CREATE OR ALTER VIEW vw_TimpMediuRezolvare_Categorie AS
    SELECT
        c.idCategorie,
        c.Denumire AS Categorie,
        COUNT(t.idTicket) AS NrTicheteRezolvate,
        AVG(DATEDIFF(MINUTE, t.DataCreare, t.DataRezolvare) / 60.0) AS TimpMediuRezolvare
    FROM Tickete t
    JOIN Categorii c ON c.idCategorie = t.idCategorie
    WHERE t.DataRezolvare IS NOT NULL
    GROUP BY c.idCategorie, c.Denumire;
GO

-- 2b. Timp mediu de rezolvare pe responsabil in ore
CREATE OR ALTER VIEW vw_TimpMediuRezolvare_Responsabil AS
    SELECT
        p.Marca AS idResponsabil,
        p.Nume AS Responsabil,
        COUNT(t.idTicket) AS NrRezolvate,
        AVG(DATEDIFF(MINUTE, t.DataCreare, t.DataRezolvare)/60.0) AS TimpMediuRezolvare
    FROM Tickete t
    JOIN Personal p ON p.Marca = t.idResponsabil
    WHERE t.DataRezolvare IS NOT NULL
    GROUP BY p.Marca, p.Nume;
GO

-- 3. Respectare SLA, adica cat % din tickete au fost rezolvate in termenul de timp asociat categoriei
CREATE OR ALTER VIEW vw_RespectareSLA AS
    SELECT
        c.Denumire AS Categorie,
        c.SLA_ore,
        COUNT(t.idTicket) AS NrTicheteRezolvate,
        SUM(CASE WHEN DATEDIFF(MINUTE, t.DataCreare, t.DataRezolvare) / 60.0 <= c.SLA_ore
                 THEN 1 ELSE 0 END) AS NrInTermen, -- Numarul de tickete care au fost rezolvate in termen
        CAST(100.0 *
             SUM(CASE WHEN DATEDIFF(MINUTE, t.DataCreare, t.DataRezolvare) / 60.0 <= c.SLA_ore
                      THEN 1 ELSE 0 END) -- Insumam cate tickete au fost rezolvate in termen
             / NULLIF(COUNT(t.idTicket), 0) -- Impartim pe numarul total de tickete rezolvate
             AS DECIMAL(5,2)) AS ProcentRespectareSLA -- Avem procentul de tickete rezolvate in termen
    FROM Tickete t
    JOIN Categorii c ON c.idCategorie = t.idCategorie
    WHERE t.DataRezolvare IS NOT NULL
    GROUP BY c.Denumire, c.SLA_ore; -- Grupam in functie de categorie
GO

-- 4. Activitate pe responsabil intr-o perioada (nr. preluate / rezolvate + timp lucrat)
GO
CREATE OR ALTER PROCEDURE usp_ActivitateResponsabil
    @DeLa   DATE = NULL,
    @PanaLa DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        p.Marca                                   AS idResponsabil,
        p.Nume                                    AS Responsabil,
        COUNT(DISTINCT CASE WHEN t.idResponsabil = p.Marca THEN t.idTicket END)      AS NrPreluate,
        COUNT(DISTINCT CASE WHEN t.DataRezolvare IS NOT NULL THEN t.idTicket END)    AS NrRezolvate,
        ISNULL(SUM(a.DurataMinute),0)             AS MinuteLucrate
    FROM Personal p
    LEFT JOIN Tickete t          ON t.idResponsabil = p.Marca
                                 AND (@DeLa   IS NULL OR t.DataCreare >= @DeLa)
                                 AND (@PanaLa IS NULL OR t.DataCreare <  DATEADD(DAY,1,@PanaLa))
    LEFT JOIN ActivitatiTicket a ON a.idTicket = t.idTicket
                                 AND a.idResponsabil = p.Marca
    GROUP BY p.Marca, p.Nume;
END
GO

-- 5a. Timp efectiv lucrat pe ticket
CREATE OR ALTER VIEW vw_TimpEfectiv_Ticket AS
    SELECT
        t.idTicket,
        t.Titlu,
        SUM(a.DurataMinute) AS TotalMinute,
        CAST(SUM(a.DurataMinute)/60.0 AS DECIMAL(10,2)) AS TotalOre
    FROM Tickete t
    JOIN ActivitatiTicket a ON a.idTicket = t.idTicket
    GROUP BY t.idTicket, t.Titlu;
GO

-- 5b. Timp efectiv lucrat pe responsabil
GO
CREATE OR ALTER VIEW vw_TimpEfectiv_Responsabil AS
    SELECT
        p.Marca                                          AS idResponsabil,
        p.Nume                                           AS Responsabil,
        COUNT(DISTINCT a.idTicket)                       AS NrTicheteLucrate,
        COUNT(a.idActivitate)                            AS NrActivitati,
        SUM(a.DurataMinute)                              AS TotalMinute,
        CAST(SUM(a.DurataMinute)/60.0 AS DECIMAL(10,2))  AS TotalOre
    FROM ActivitatiTicket a
    JOIN Personal p ON p.Marca = a.idResponsabil
    GROUP BY p.Marca, p.Nume;
GO

-- 6. Comparatie eficienta (timp efectiv vs. timp calendaristic)
CREATE OR ALTER VIEW vw_Eficienta AS
    SELECT
        t.idTicket,
        t.Titlu,
        SUM(a.DurataMinute)                                        AS MinuteEfective,
        DATEDIFF(MINUTE, t.DataCreare, t.DataRezolvare)            AS MinuteCalendaristice,
        CAST(100.0 * SUM(a.DurataMinute)
             / NULLIF(DATEDIFF(MINUTE, t.DataCreare, t.DataRezolvare),0)
             AS DECIMAL(9,2))                                      AS ProcentEficienta -- 9,2 nu 5,2: procentul poate depasi 999.99 cand pe un ticket rezolvat repede s-au raportat mai multe activitati decat timpul calendaristic scurs
    FROM Tickete t
    JOIN ActivitatiTicket a ON a.idTicket = t.idTicket
    WHERE t.DataRezolvare IS NOT NULL
    GROUP BY t.idTicket, t.Titlu, t.DataCreare, t.DataRezolvare;
GO
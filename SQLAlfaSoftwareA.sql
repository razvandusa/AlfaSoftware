-- A1 SELECT de baza
SELECT cod_fiscal, denumire, localitate
FROM Terti
WHERE RTRIM(localitate) = 'Bucuresti' -- RTRIM elimina spatiile de la sfarsitul valorilor din campul localitate

SELECT TOP 20 *
FROM Nomencl
WHERE Tip = 'A'
ORDER BY Pret_vanzare DESC

SELECT DISTINCT Judet
FROM Terti
WHERE Judet IS NOT NULL AND RTRIM(Judet) <> ''

SELECT email
FROM Terti
WHERE email LIKE '%asw.ro%'

-- ?
SELECT *
FROM Nomencl
WHERE COTA_TVA IN (5,9,19)
    AND Pret_vanzare BETWEEN 10 AND 100

-- A2 Functii & expresii
SELECT Nume, 
        DATEDIFF(YEAR, Data_nasterii, GETDATE()) AS varsta, -- DATEDIFF(datepart, startdate, enddate), datepart: unitatea in care vrei diferenta
        DATEDIFF(YEAR, Data_angajarii_in_unitate, GETDATE()) AS vechime_in_firma
FROM Personal

SELECT Tert,
    CASE
        WHEN Tert_extern = '1'
        THEN 'Extern'
        ELSE 'Intern'
    END AS Tip_relatie
FROM Terti

SELECT Nume,
        COALESCE(NULLIF(telefon, ''), 'FARA TELEFON') AS Telefon -- COALESCE este folosit pentru a inlocui valorile NULL, iar NULLIF transforma sirul gol in NULL
FROM Personal

SELECT numar,
        YEAR(data) AS an, -- YEAR extrage anul dintr-un datetime
        DATENAME(MONTH, data) AS luna -- DATENAME returns the name of a part from a datetime
FROM Contracte
WHERE tip = 'CL'

-- A3 Agregari & grupare
SELECT Localitate,
        COUNT(*) as Numar
FROM Terti
GROUP BY Localitate
ORDER BY Numar DESC

SELECT idContract,
        SUM(cantitate * pret)
FROM PozContracte
GROUP BY idContract
HAVING SUM(cantitate * pret) > 10000

SELECT Loc_de_munca,
        AVG(Salar_de_incadrare) AS salariul_mediu,
        MIN(Salar_de_incadrare) AS salariu_minim,
        MAX(Salar_de_incadrare) AS salariu_maxim
FROM Personal
GROUP BY Loc_de_munca

SELECT Tip,
        COUNT(*) as numarul_de_articole
FROM nomencl
GROUP BY Tip
HAVING COUNT(*) > 1000

SELECT YEAR(data),
        tip
FROM Contracte
WHERE tip IS NOT NULL AND YEAR(data) IS NOT NULL
GROUP BY Year(data), tip

-- A4 JOIN-uri
SELECT idContract, Terti.Denumire
FROM Contracte
INNER JOIN Terti ON Contracte.tert = Terti.Tert

SELECT Terti.Denumire,
        COUNT(C.idContract) AS numar_contracte
FROM Terti
LEFT JOIN Contracte C ON Terti.Tert = C.tert
GROUP BY Terti.Denumire

SELECT N.Denumire, N.Grupa
FROM nomencl N
INNER JOIN Grupe G ON G.Tip_de_nomenclator = N.Tip AND N.Grupa = G.Grupa

SELECT G.Grupa, G2.Denumire
FROM Grupe G
LEFT JOIN Grupe G2 ON G.Grupa = G2.grupa_parinte

-- A5 Subinterogari & CTE
SELECT * FROM nomencl
WHERE Pret_vanzare > (SELECT AVG(Pret_vanzare) FROM nomencl)
ORDER BY Pret_vanzare

SELECT * FROM Terti T1
WHERE T1.Sold_maxim_ca_beneficiar = (SELECT MAX(Sold_maxim_ca_beneficiar) FROM Terti T2 WHERE T2.Judet = T1.Judet)

WITH cte AS (
        SELECT PC.idContract,
                SUM(PC.cantitate * PC.pret * C.curs) AS valoare_contract
        FROM PozContracte PC INNER JOIN Contracte C ON PC.idContract = C.idContract AND C.curs IS NOT NULL
        GROUP BY PC.idContract
)
SELECT idContract, valoare_contract
FROM cte WHERE valoare_contract > (SELECT AVG(valoare_contract) FROM cte)

-- A6 Functii fereastra & APPLY
WITH cte AS (
        SELECT Nume,
        Loc_de_munca,
        ROW_NUMBER() OVER ( -- da fiecarui rand un numar unic secvential
                PARTITION BY Loc_de_munca -- imparte datele in grupuri separate, cate unul pentru fiecare valoare distincta din loc_de_munca
                ORDER BY salar_de_baza DESC
        ) AS rank
FROM Personal
)
SELECT * 
FROM cte
WHERE rank <= 3

SELECT idContract,
        cantitate*pret AS valoare,
        SUM(cantitate*pret) OVER(PARTITION BY idContract) AS totalContract, -- totalul contractului calculat o data pentru toata partitia dar afisat pe fiecare rand din contract
        (cantitate*pret) * 100.0 / NULLIF(SUM(cantitate*pret) OVER(PARTITION BY idContract), 0) AS procentDinTotal
FROM PozContracte

SELECT T.Denumire,
        T.Sold_ca_beneficiar,
        RANK() OVER(ORDER BY T.Sold_ca_beneficiar DESC)
FROM Terti T

SELECT idContract, tabel_valoare_contract.valoare
FROM Contracte C
CROSS APPLY ( -- pentru fiecare rand din Contracte se ruleaza subquery-ul CROSS APPLY
        SELECT TOP 3 PC.cantitate * PC.pret AS valoare -- se iau cele mai valoroase 3 pozitii a fiecarui contract
        FROM PozContracte PC
        WHERE C.idContract = PC.idContract
        ORDER BY PC.cantitate * PC.pret DESC
) AS tabel_valoare_contract

SELECT T.Tert, contract.idContract
FROM Terti T
OUTER APPLY ( -- Outer apply pastreaza toate randurile din stanga (tertii) chiar daca nu gaseste nici un contract
        SELECT TOP 1 C.idContract as idContract
        FROM Contracte C
        WHERE C.tert = T.Tert
        ORDER BY C.data DESC
) AS contract

SELECT YEAR(data) AS an,
        SUM(CASE WHEN tip='AR' THEN 1 ELSE 0 END) AS AR,
        SUM(CASE WHEN tip='AT' THEN 1 ELSE 0 END) AS AT,
        SUM(CASE WHEN tip='BL' THEN 1 ELSE 0 END) AS BL,
        SUM(CASE WHEN tip='CA' THEN 1 ELSE 0 END) AS CA,
        SUM(CASE WHEN tip='CB' THEN 1 ELSE 0 END) AS CB,
        SUM(CASE WHEN tip='CC' THEN 1 ELSE 0 END) AS CC,
        SUM(CASE WHEN tip='CE' THEN 1 ELSE 0 END) AS CE,
        SUM(CASE WHEN tip='CF' THEN 1 ELSE 0 END) AS CF,
        SUM(CASE WHEN tip='CL' THEN 1 ELSE 0 END) AS CL,
        SUM(CASE WHEN tip='CM' THEN 1 ELSE 0 END) AS CM,
        SUM(CASE WHEN tip='CS' THEN 1 ELSE 0 END) AS CS,
        SUM(CASE WHEN tip='CT' THEN 1 ELSE 0 END) AS CT,
        SUM(CASE WHEN tip='DS' THEN 1 ELSE 0 END) AS DS,
        SUM(CASE WHEN tip='DT' THEN 1 ELSE 0 END) AS DT,
        SUM(CASE WHEN tip='FN' THEN 1 ELSE 0 END) AS FN,
        SUM(CASE WHEN tip='ID' THEN 1 ELSE 0 END) AS ID,
        SUM(CASE WHEN tip='LD' THEN 1 ELSE 0 END) AS LD,
        SUM(CASE WHEN tip='LF' THEN 1 ELSE 0 END) AS LF,
        SUM(CASE WHEN tip='PR' THEN 1 ELSE 0 END) AS PR,
        SUM(CASE WHEN tip='RN' THEN 1 ELSE 0 END) AS RN,
        SUM(CASE WHEN tip='SL' THEN 1 ELSE 0 END) AS SL
FROM Contracte
GROUP BY YEAR(data)
ORDER BY an

-- A7 XML (campul detalii)
SELECT * 
FROM Terti
WHERE detalii.value('(/row/@_persfizica)[1]', 'int') = 1 -- .value(xquery, sql_type), [1] spune sa ia primul primul atribut _persfizica gasit, @ spune ca este un atribut

SELECT Tert,
        detalii.value('(/row/@caen)[1]', 'varchar(50)') AS CAEN,
        detalii.value('(/row/@zona)[1]', 'varchar(50)') AS Zona
FROM Terti
WHERE detalii.value('(/row/@_efactura)[1]', 'int') = 1

SELECT COUNT(*) AS numar,
        zona
FROM (
        SELECT detalii.value('(/row/@zona)[1]', 'varchar(50)') AS zona
        FROM Terti
) AS tabel
GROUP BY zona

-- A8 DDL (Data Definition Language) & CRUD
ALTER TABLE Terti
ADD observatii_intern VARCHAR(200)
ALTER TABLE Terti
DROP COLUMN observatii_intern

-- Asa verific ce tip de date are un camp dintr-un tabel
/*
SELECT DATA_TYPE, CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Terti' AND COLUMN_NAME = 'Tert'
*/

CREATE TABLE TertImportant (
        idTertImportant INT IDENTITY(1,1) PRIMARY KEY,
        grad_importanta INT DEFAULT 1 CHECK (grad_importanta BETWEEN 1 AND 5),
        tertAsociat CHAR(13) FOREIGN KEY REFERENCES Terti(Tert)
)

INSERT INTO TertImportant (grad_importanta, tertAsociat) VALUES
        (2, '00098090210'),
        (1, '01112101'),
        (2, '05021910')

BEGIN TRAN
UPDATE Terti
SET zileScadenta = zileScadenta + 5
WHERE Judet = 'CJ'
SELECT Tert, zileScadenta FROM Terti WHERE Judet = 'CJ' -- verific modificarea
COMMIT TRAN -- daca e ok
-- ROLLBACK TRAN -- daca nu e ok

DELETE FROM PozContracte
WHERE NOT EXISTS (
        SELECT 1 
        FROM Contracte C
        WHERE C.idContract = PozContracte.idContract -- cautam sa vedem ce contracte nu avem care se regasesc in PozContracte
)

MERGE TertImportant
USING Terti ON TertImportant.tertAsociat = Terti.Tert
WHEN MATCHED THEN
        UPDATE SET TertImportant.grad_importanta = 1 -- cand gasim punem gradul de importanta la 1
WHEN NOT MATCHED THEN 
        INSERT (grad_importanta, tertAsociat)
        VALUES (
                2,
                Terti.Tert
        );

-- A9 Programare T-SQL
GO
CREATE FUNCTION fn_ValoareContract (@idContract INT)
RETURNS FLOAT
AS
BEGIN
        RETURN (
                SELECT SUM(cantitate*pret) AS valoare_contract
                FROM PozContracte
                WHERE idContract = @idContract
        )
END
GO

SELECT dbo.fn_ValoareContract(7170)

GO
CREATE FUNCTION fn_PozitiiContract (@idContract INT)
RETURNS TABLE
AS
RETURN (
        SELECT idContract,
                cantitate * pret AS valoare
        FROM PozContracte
        WHERE idContract = @idContract
)
GO

SELECT * FROM dbo.fn_PozitiiContract(7170)

GO
CREATE PROCEDURE usp_ContracteTert (@tert VARCHAR(20), @dela DATETIME, @panala DATETIME)
AS
BEGIN
        SELECT *
        FROM Contracte C
        WHERE C.tert = @tert AND C.data BETWEEN @dela AND @panala
END
GO

EXEC usp_ContracteTert @tert='10368426', @dela='2014-09-14 00:00:00.000', @panala='2014-09-16 00:00:00.000'

GO
CREATE PROCEDURE usp_AdaugaContract 
        @numar VARCHAR(50),
        @data DATE,
        @tip VARCHAR(10),
        @tert VARCHAR(20),
        @curs FLOAT,
        @cantitate INT,
        @pret DECIMAL(18,2),
        @idContract INT OUTPUT
AS
BEGIN
        BEGIN TRY
                BEGIN TRAN
                INSERT INTO Contracte(numar, data, tip, tert, curs)
                VALUES(@numar, @data, @tip, @tert, @curs)
                SET @idContract = SCOPE_IDENTITY()
                INSERT INTO PozContracte(idContract, cantitate, pret)
                VALUES(@idContract, @cantitate, @pret)
                COMMIT TRAN
        END TRY
        BEGIN CATCH
                IF @@TRANCOUNT > 0
                        ROLLBACK TRAN
                THROW
        END CATCH
END
GO

DECLARE @newId INT
EXEC usp_AdaugaContract
        @numar = 'C-001',
        @data = '2026-07-23',
        @tip = 'CL',
        @tert = '10976739',
        @curs = 1,
        @cantitate = 10,
        @pret = 100,
        @idContract = @newId OUTPUT

SELECT @newId AS idContractNou

CREATE TABLE Jurnal (
        id INT IDENTITY(1,1) PRIMARY KEY,
        idContract INT,
        explicatieVeche NVARCHAR(500),
        explicatieNoua NVARCHAR(500)
)

GO
CREATE TRIGGER tr_Jurnal
ON Contracte
AFTER UPDATE
AS
BEGIN
        IF UPDATE(explicatii)
        BEGIN
                INSERT INTO Jurnal(idContract, explicatieVeche, explicatieNoua)
                SELECT I.idContract, D.explicatii, I.explicatii
                FROM inserted I
                JOIN deleted D ON I.idContract = D.idContract
                WHERE ISNULL(I.explicatii, '') <> ISNULL(d.explicatii, '')
        END
END

UPDATE Contracte SET explicatii = 'text nou de test' WHERE idContract = 7172

SELECT * FROM Jurnal



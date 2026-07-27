-- ==============================
-- | B3: Trigger de jurnalizare |
-- ==============================

GO
CREATE OR ALTER TRIGGER trg_Tickete_Jurnalizare
ON Tickete
AFTER UPDATE -- Ruleaza dupa orice UPDATE pe tabela Tickete
AS
BEGIN
    SET NOCOUNT ON;

    -- Ne intereseaza doar cazul in care s-a schimbat efectiv starea ticketului
    IF NOT UPDATE(Stare)
        RETURN; -- Daca starea nu s-a schimbat, adica coloana Stare nu a fost inclusa in UPDATE atunci iesim

    -- Regula 2: un ticket INCHIS nu poate fi redeschis (starea inchis e finala)
    IF EXISTS (
        SELECT 1
        FROM deleted d
        JOIN inserted i ON i.idTicket = d.idTicket
        JOIN StariTicket s ON s.idStare = d.Stare -- Match-uim starea ticketului (foreign key) inainte de UPDATE (deleted) cu id-ul starii care corespunde cu tipului 'inchis'
        WHERE s.TipStare = 'inchis'
          AND i.Stare <> d.Stare -- Verificam daca starea ticketului inainte de UPDATE (folosind delted) s-a schimbat intr-o stare diferita (folosind inserted)
    )
    BEGIN
        RAISERROR (N'Un ticket inchis nu poate fi redeschis sau modificat de stare.', 16, 1); -- Daca exista un astfel de UPDATE pe un ticket cu starea 'inchis' se va arunca eroare cu nivelul de severitate 16 (standard pentru erori "de business")
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- Regula 3: la trecerea in 'Rezolvat' a starii ticketului se completeaza automat DataRezolvare
    UPDATE t
        SET t.DataRezolvare = ISNULL(t.DataRezolvare, GETDATE()) -- Verificam daca a fost deja setata data, daca nu a fost atunci setam data curenta cu GETDATE()
    FROM Tickete t
    JOIN inserted i ON i.idTicket = t.idTicket
    JOIN deleted  d ON d.idTicket = t.idTicket
    JOIN StariTicket s ON s.idStare = i.Stare
    WHERE s.Denumire = N'Rezolvat' -- Verificam ca starea ticketului s-a transformat in 'Rezolvat'
      AND i.Stare <> d.Stare;

    -- Regula 1: orice schimbare de stare -> se scrie automat in JurnalTickete
    INSERT INTO JurnalTickete (idTicket, Stare, DataModificare, Utilizator, Comentariu)
    SELECT
        i.idTicket,
        i.Stare,
        GETDATE(),
        ISNULL(SUSER_SNAME(), N'sistem'), -- Utilizatorul SQL curent
        N'Schimbare stare: ' + ds.Denumire + N' -> ' + isr.Denumire
    FROM inserted i
    JOIN deleted  d  ON d.idTicket = i.idTicket
    JOIN StariTicket ds  ON ds.idStare  = d.Stare -- Starea veche
    JOIN StariTicket isr ON isr.idStare = i.Stare -- Starea noua
    WHERE i.Stare <> d.Stare; -- Verificam ca starea s-a modificat
END
GO
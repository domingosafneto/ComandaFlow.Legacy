USE [master];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF DB_ID('selfservice_legacy') IS NULL
BEGIN
    CREATE DATABASE [selfservice_legacy];
    PRINT 'Banco selfservice_legacy criado.';
END
ELSE
    BEGIN
        PRINT 'Banco selfservice_legacy ja existe.';
    END
GO


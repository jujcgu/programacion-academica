USE [academia3000_sergiomartinez]
GO

/****** Objeto: UserDefinedFunction [dbo].[VarBinToHexStr] Fecha de script: 25/11/2026 11:28:33 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Juan Castro
-- Create date: 29/03/2012
-- Description:	Convertir varbinary a string
-- =============================================
CREATE FUNCTION [dbo].[VarBinToHexStr] 
(
	-- Add the parameters for the function here
	@varbin varbinary(64)	
)
RETURNS VARCHAR(64)
AS
BEGIN
	-- Declare the return variable here
	DECLARE @hexstr varchar(8000), @hex char(2), @i int, @msc int, @lsc int, @count int
	
	-- Add the T-SQL statements to compute the return value here
	SET @hexstr = '0x'

	SET @count = LEN(@varbin)

	SET @i = 1

	WHILE (@i <= @count)

	BEGIN

		SET @msc = FLOOR(CAST(SUBSTRING(@varbin, @i, 1) AS int) / 16)

		SET @lsc = CAST(SUBSTRING(@varbin, @i, 1) AS int) % 16

		SET @hexstr = @hexstr + CASE WHEN @msc >= 10 THEN CHAR(@msc + 55) ELSE CAST(@msc AS varchar(1)) END + CASE WHEN @lsc >= 10 THEN CHAR(@lsc + 55) ELSE CAST(@lsc AS varchar(1)) END

		SET @i = @i+1

	END

	-- Return the result of the function
	RETURN @hexstr
END
GO



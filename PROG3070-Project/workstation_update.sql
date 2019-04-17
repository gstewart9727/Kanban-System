USE [Kanban]
GO
/****** Object:  StoredProcedure [dbo].[workstation_update]    Script Date: 2019-04-16 9:47:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Procedure to check existence of station, creating it if needed
ALTER PROCEDURE [dbo].[workstation_update]
	@StationNumber int,	-- Desired Station Number
	@DefectRate	float -- Defect rate of the employee
AS

BEGIN
BEGIN TRANSACTION t1

	DECLARE @Status int
	DECLARE @whatFormat int
	DECLARE @Lower int
	DECLARE @Upper int
	DECLARE @TestResult varchar(4)

	DECLARE @NewLampNumber nchar(8)		
	DECLARE @NewTrayNumber nchar(8)		-- Formatted tray number with updated value
	DECLARE @LatestTrayValue nchar(6)	--Tray Number with padding and the number but without FL 
	DECLARE @LastestTrayNumber int		--The actual tray number without the FL and the padding

	-- Checking if the order table has at least one
	SET @Status = (SELECT Value FROM Configuration WHERE Item='Order')
	IF @Status <= 0
		BEGIN
			ROLLBACK TRANSACTION t1
			RETURN -1
		END
	ELSE
		BEGIN
		SET @Status = (SELECT COUNT(*) FROM [Stock] WHERE Station = @StationNumber AND Stock <= 0)
		IF @Status >= 1
			BEGIN
				ROLLBACK TRANSACTION t1
				RETURN -1
			END
		ELSE
			BEGIN
				UPDATE Stock SET Stock -= 1 WHERE Station = @StationNumber
			END
		END

		
	-- Generating a random number to simulate a test result 
	SET @Lower = 0 ---- The lowest random number
	SET @Upper = 2 ---- The highest random number
	SET @Status = (SELECT ROUND(((@Upper - @Lower -1) * RAND() + @Lower * @DefectRate), 0))
	IF @Status = 1
		BEGIN
			SET @TestResult = 'Pass'
		END
	ELSE
		BEGIN
			SET @TestResult = 'Fail'
		END

	--Generating a new value for the Product Table
	SET @Status = (SELECT TOP 1 LampNumber FROM Product ORDER BY TrayNumber DESC)
	IF @Status < 60
		BEGIN
			SET @NewLampNumber = RIGHT('00' + CAST((SELECT TOP 1 Right(LampNumber,2) FROM Product ORDER BY TrayNumber DESC) + 1 AS varchar), 2)
			SET @whatFormat = 1
		END
	ELSE
		BEGIN
			SELECT @LastestTrayNumber = RIGHT(TrayNumber, 6) FROM Product
			SET @LastestTrayNumber += 1
			SELECT @LatestTrayValue =  (SELECT TOP 1 RIGHT('000000' + CAST(@LastestTrayNumber AS varchar), 6) FROM Product ORDER BY TrayNumber DESC)
			SET @NewTrayNumber = 'FL' + @LatestTrayValue
			SET @NewLampNumber =  RIGHT('00' + CAST(1 AS varchar), 2)
			SET @whatFormat = 2
		END

-- Checking if the order table has at least one
	SET @Status = (SELECT Value FROM Configuration WHERE Item='Order')
	IF @Status <= 0
		BEGIN
			ROLLBACK TRANSACTION t1
			RETURN -1
		END
	ELSE
		BEGIN
			IF @whatFormat = 1
				BEGIN
					INSERT INTO Product(TrayNumber, LampNumber, StationNumber, TestResult) 
					VALUES ((SELECT TOP 1 TrayNumber FROM Product ORDER BY TrayNumber DESC), @NewLampNumber, @StationNumber, @TestResult)
					UPDATE Configuration SET Value -= 1 WHERE Item = 'Order'
				END
			ELSE
				BEGIN
					INSERT INTO Product(TrayNumber, LampNumber, StationNumber, TestResult) 
					VALUES (@NewTrayNumber, @NewLampNumber, @StationNumber, @TestResult)
					UPDATE Configuration SET Value -= 1 WHERE Item = 'Order'
				END
		END
COMMIT TRANSACTION t1
RETURN @Status
END
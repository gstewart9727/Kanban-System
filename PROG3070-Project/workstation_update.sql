--Project Name  : PROG3070-Project
--Programmer    : Oloruntoba Samuel Lagunju
--Version Date  : 2019-04-18
--Description   : Procedure to insert a new finished product

USE [Kanban System Data]
GO
/****** Object:  StoredProcedure [dbo].[workstation_update]    Script Date: 2019-04-17 7:59:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Procedure to simulate inersting in the product table
ALTER PROCEDURE [dbo].[workstation_update]
	@StationNumber int,	-- Desired Station Number
	@DefectRate	float -- Defect rate of the employee
AS

BEGIN
BEGIN TRANSACTION t1

	DECLARE @Status int					-- Variable to keep track of the store procedure station
	DECLARE @whatFormat int				-- Variable that determines tp insert a new lamp number, or new tray number
	DECLARE @Lower int					-- Lowest number for the random range
	DECLARE @Upper int					-- Highest number for the random range
	DECLARE @TestResult varchar(4)		-- Variable that determines if the part creation is a pass or fail

	DECLARE @NewLampNumber nchar(8)		-- Formatted lamp number
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
		-- Checking if the station has all its part stock greater than 0
		SET @Status = (SELECT COUNT(*) FROM [Stock] WHERE Station = @StationNumber AND Stock <= 0)
		IF @Status >= 1
			BEGIN
				ROLLBACK TRANSACTION t1
				RETURN -1
			END
		ELSE
			BEGIN
				-- Decrementing all the station's part stock number
				UPDATE Stock SET Stock = Stock - 1 WHERE Station = @StationNumber AND Part  = 1
				UPDATE Stock SET Stock = Stock - 1 WHERE Station = @StationNumber AND Part  = 2
				UPDATE Stock SET Stock = Stock - 1 WHERE Station = @StationNumber AND Part  = 3
				UPDATE Stock SET Stock = Stock - 1 WHERE Station = @StationNumber AND Part  = 4
				UPDATE Stock SET Stock = Stock - 1 WHERE Station = @StationNumber AND Part  = 5
				UPDATE Stock SET Stock = Stock - 1 WHERE Station = @StationNumber AND Part  = 6
			END
		END		
	-- Generating a random number to simulate a test result 
	SET @Lower = 0 ---- The lowest random number
	SET @Upper = 2 ---- The highest random number
	SET @Status = (SELECT RAND()* (@Upper- @Lower) + @Lower)
	IF @Status = @DefectRate
		BEGIN
			SET @TestResult = 'Fail'
		END
	ELSE
		BEGIN
			SET @TestResult = 'Pass'
		END
	--Generating a new value for the Product Table
	SET @Status = (SELECT COUNT(*) TrayNumber FROM Product)
	-- If there are no finished products, create one
	IF @Status < 1
		BEGIN
			SET @NewTrayNumber = 'FL000001'
			SET @NewLampNumber = '01'
		END
	ELSE
		BEGIN
			-- Getting the latest lamp number and checking if its reached 60
			-- If it hasn't, create a new lamp number 
			SET @Status = (SELECT TOP 1 LampNumber FROM Product ORDER BY TrayNumber DESC)
			IF @Status < 60
				BEGIN
					SET @NewLampNumber = RIGHT('00' + CAST((SELECT TOP 1 Right(LampNumber,2) FROM Product ORDER BY TrayNumber DESC) + 1 AS varchar), 2)
					SET @NewTrayNumber = (SELECT TOP 1 TrayNumber FROM Product ORDER BY TrayNumber DESC) 
					SET @whatFormat = 1
				END
			ELSE
				-- If it has reached 60, create a new tray number
				BEGIN
					SELECT @LastestTrayNumber = RIGHT(TrayNumber, 6) FROM Product
					SET @LastestTrayNumber += 1
					SELECT @LatestTrayValue =  (SELECT TOP 1 RIGHT('000000' + CAST(@LastestTrayNumber AS varchar), 6) FROM Product ORDER BY TrayNumber DESC)
					SET @NewTrayNumber = 'FL' + @LatestTrayValue
					SET @NewLampNumber =  RIGHT('00' + CAST(1 AS varchar), 2)
					SET @whatFormat = 2
				END
		END	
	BEGIN TRY 
		-- Insert the new values into the product table
		INSERT INTO Product(TrayNumber, LampNumber, StationNumber, TestResult) 
		VALUES (@NewTrayNumber, @NewLampNumber, @StationNumber, @TestResult)
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION t1
		RETURN -1
	END CATCH
	--Updating the order table
UPDATE Configuration SET Value -= 1 WHERE Item = 'Order'
SET @Status = 1
COMMIT TRANSACTION t1
RETURN @Status
END
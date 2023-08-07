-- DATA CLEANING IN SQL QUERIES
-- Dataset: Nashville Housing Data
-- Data obtained from kaggle.com 

SELECT *
FROM DataCleaning..NashHouse

-- Standardize Date Format

SELECT SaleDate, CONVERT(Date,SaleDate)
FROM DataCleaning..NashHouse

ALTER TABLE NashHouse
ADD SaleDateConverted date;

UPDATE NashHouse
SET SaleDateConverted = CONVERT(Date,SaleDate)

-- Populate Property Address Data

SELECT *
FROM DataCleaning..NashHouse
--WHERE PropertyAddress IS NULL
ORDER BY ParcelID

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM DataCleaning..NashHouse a
JOIN DataCleaning..NashHouse b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM DataCleaning..NashHouse a
JOIN DataCleaning..NashHouse b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL

-- Breakdown Address into (Address/City/State)

--1) Using Substring

SELECT PropertyAddress
FROM DataCleaning..NashHouse

SELECT PropertyAddress,
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) AS Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress))AS City
FROM DataCleaning..NashHouse

ALTER TABLE NashHouse
ADD PropertySplitAddress nvarchar(255), PropertySplitCity nvarchar(255);

UPDATE NashHouse
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1),
	PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress))

--2) Using Parsename

SELECT OwnerAddress
FROM DataCleaning..NashHouse

SELECT OwnerAddress,
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) AS Address,
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) AS City,
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) AS State
FROM DataCleaning..NashHouse

ALTER TABLE NashHouse
ADD OwnerSplitAddress nvarchar(255), OwnerSplitCity nvarchar(255), OwnerSplitState nvarchar(255);

UPDATE NashHouse
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
	OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
	OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

-- Standardize SoldAsVacant Data(Y, N, Yes, No) into Yes and No 

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM DataCleaning..NashHouse
GROUP BY SoldAsVacant
ORDER BY 2

UPDATE NashHouse
SET SoldAsVacant = 
					CASE
						WHEN SoldAsVacant = 'Y' THEN 'Yes'
						WHEN SoldAsVacant = 'N' THEN 'No'
						ELSE SoldAsVacant
					END

-- Removing Duplicates using CTE(Common Table Expression)

WITH RowNumCTE AS (
					SELECT *, ROW_NUMBER() OVER (PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
					ORDER BY UniqueID) row_num
				FROM DataCleaning..NashHouse
				)

--SELECT *
--FROM RowNumCTE
--WHERE row_num >1
--ORDER BY PropertyAddress

--DELETE 
--FROM RowNumCTE
--WHERE row_num >1

-- Deleting Unused Column

ALTER TABLE NashHouse
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate

-- Cleaned Data:

SELECT *
FROM DataCleaning..NashHouse
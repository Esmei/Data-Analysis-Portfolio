/* SQL Data Cleaning Project
1. Standardize Date Format
2. Populate Property Addresses for Missing Items
3. Breaking out Address into Individual Columns (Address, City, State etc.)
4. Change Y and N to Yes and No in "Sold as Vacant" field
5. Deal with Duplicate Data
6. Drop the unnecessary data generated while we are cleaning the data
*/

SELECT *
FROM housing_data

-----------------------------------------------------
--1. Standardize Date Format

SELECT SaleDate
FROM housing_data

ALTER TABLE housing_data
ALTER COLUMN SaleDate date

-------------------------------------------------
--2. Populate Property Addresses for Missing Items
-- Please note tha we are assuming here that for the housing items with a same Parcel ID should be having the same Property Addresses.

SELECT COUNT(DISTINCT UniqueID) -- 56477
FROM housing_data

SELECT COUNT(DISTINCT ParcelID) -- 48559
FROM housing_data
 
SELECT 
      a.UniqueID, 
      a.ParcelID,
	  a.PropertyAddress, 
	  b.UniqueID, 
	  b.ParcelID, 
	  b.PropertyAddress,
	  ISNULL(a.PropertyAddress, b.PropertyAddress)
From housing_data a
INNER JOIN housing_data b
   ON (a.ParcelID = b.ParcelID
	   AND a.[UniqueID ] <> b.[UniqueID ]
	   AND a.PropertyAddress IS NULL)

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM housing_data a
INNER JOIN housing_data b
   ON (a.ParcelID = b.ParcelID
	   AND a.[UniqueID ] <> b.[UniqueID ]
	   AND a.PropertyAddress IS NULL)
WHERE a.PropertyAddress IS NULL

SELECT *
FROM housing_data
WHERE PropertyAddress IS NULL -- There are zero results so it means our adjustment is complete.

---------------------------------------------------------------------------------------
--3. Breaking out Address into Individual Columns (Address, City, State etc.)

SELECT PropertyAddress, OwnerAddress
FROM housing_data -- Contains Address, City and State

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 ) as Address, 
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress)) as City
From housing_data

ALTER TABLE housing_data
Add PropertySplitAddress NVARCHAR(255),
    PropertySplitCity NVARCHAR(50)

Update housing_data
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 ),
    PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress))

SELECT *
FROM housing_data

Select
PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3),
PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)
From housing_data

ALTER TABLE housing_data
Add OwnerSplitAddress Nvarchar(255),
    OwnerSplitCity NVARCHAR(50),
	OwnerSplitState NVARCHAR(50)

Update housing_data
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3),
    OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2),
	OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)

SELECT *
FROM housing_data

--------------------------------------------------------------------
--4. Change Y and N to Yes and No in "Sold as Vacant" field
SELECT SoldAsVacant, COUNT(SoldAsVacant)
FROM housing_data
GROUP BY SoldAsVacant

Select SoldAsVacant
, CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
From housing_data

Update housing_data
SET SoldAsVacant = 
                  CASE When SoldAsVacant = 'Y' THEN 'Yes'
	                   When SoldAsVacant = 'N' THEN 'No'
	                   ELSE SoldAsVacant
	                   END

--5. Deal with Duplicates
---Please note that we are assuming here that items with the same ParcelID, SalePrice, SaleDate and LegalReference are duplicate data.
DROP TABLE IF EXISTS no_duplicates
SELECT *, 
       ROW_NUMBER() OVER(PARTITION BY 
                                      ParcelID,
									  SalePrice,
									  SaleDate,
									  LegalReference
							ORDER BY UniqueID) AS row_num
INTO no_duplicates
FROM housing_data

SELECT *
INTO clean_data
FROM no_duplicates
WHERE row_num = 1

SELECT DISTINCT row_num 
FROM clean_data  --Now the clean_data table has got rid of the duplicates and are better prepared for future analysis.

--6. Drop the unnecessary data generated while we are cleaning the data, 
--Please note that this is not deleting the original database.
--Generally we should not delete any data from company's database unless there are some special reasons for that and proper permission has been granted.

DROP TABLE no_duplicates

SELECT *
FROM clean_data

ALTER TABLE clean_data
DROP COLUMN row_num;


--THE END : )
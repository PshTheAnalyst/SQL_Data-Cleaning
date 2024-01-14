SELECT * FROM house.housing_data_csv;

SELECT SaleDate
FROM house.housing_data_csv;


-- Standardize Date Format

UPDATE house.housing_data_csv
SET SaleDate = STR_TO_DATE(SaleDate, '%M %e, %Y');

--------------------------------------------------------------------------------------------------------------------------

-- Populate Property Address data

SELECT * FROM house.housing_data_csv 
WHERE ParcelID is null;


SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress) 
FROM house.housing_data_csv a
JOIN house.housing_data_csv b
ON a.ParcelID = b.ParcelID 
AND a.UniqueID <> b.UniqueID
Where a.PropertyAddress is null;

UPDATE house.housing_data_csv a
JOIN house.housing_data_csv b
ON a.ParcelID = b.ParcelID 
AND a.UniqueID <> b.UniqueID
SET a.PropertyAddress = COALESCE(a.PropertyAddress, b.PropertyAddress)
WHERE a.PropertyAddress is null;


-- Breaking out Address into Individual Columns (Address, City, State)

SELECT PropertyAddress FROM house.housing_data_csv;

SELECT 
SUBSTRING(PropertyAddress,1,CHARINDEX(',', PropertyAddress,-1)) as Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress,+1), 
LENGTH(PropertyAddress)) as Address
FROM house.housing_data_csv;



ALTER TABLE housing_data_csv
Add PropertySplitAddress Nvarchar(255);

Update NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 );


ALTER TABLE housing_data_csv
Add PropertySplitCity Nvarchar(255);

Update housing_data_csv
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress));





Select OwnerAddress,
TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', -2), ',', 1))
From house.housing_data_csv;

ALTER TABLE house.housing_data_csv
ADD COLUMN Street VARCHAR(255),
ADD COLUMN City VARCHAR(255),
ADD COLUMN State VARCHAR(255);


UPDATE house.housing_data_csv
SET 
    Street = TRIM(SUBSTRING_INDEX(OwnerAddress, ',', 1)),
    City = TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', -2), ',', 1)),
    State = TRIM(SUBSTRING_INDEX(OwnerAddress, ',', -1));
    


--------------------------------------------------------------------------------------------------------------------------


-- Change Y and N to Yes and No in "Sold as Vacant" field


Select Distinct(SoldAsVacant), Count(SoldAsVacant)
From house.housing_data_csv
Group by SoldAsVacant
order by 2;


Select SoldAsVacant, CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
FROM house.housing_data_csv;


Update house.housing_data_csv
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END;
       
       

-----------------------------------------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates

DELETE r
FROM house.housing_data_csv r
JOIN (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY ParcelID,
                        PropertyAddress,
                        SalePrice,
                        SaleDate,
                        LegalReference
            ORDER BY UniqueID
        ) AS row_num
    FROM house.housing_data_csv
) RowNumSubquery ON r.UniqueID = RowNumSubquery.UniqueID
WHERE row_num > 1;


---------------------------------------------------------------------------------------------------------

-- Delete Unused Columns



Select *
From house.housing_data_csv;


ALTER TABLE house.housing_data_csv
DROP COLUMN OwnerAddress,
DROP COLUMN TaxDistrict,
DROP COLUMN PropertyAddress,
DROP COLUMN SaleDate;




       
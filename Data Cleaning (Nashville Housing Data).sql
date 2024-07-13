--DATA CLEANING IN SQL

Select *
From PortfolioProject..NashvilleHousing

==============================================================================================================================================================================================

--1. Standardize Date Format 

Select SaleDate, CONVERT(Date, SaleDate)
From PortfolioProject..NashvilleHousing

/*Update NashvilleHousing
SET SaleDate = CONVERT(Date, SaleDate) */

ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date

Update NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate) 


Select SaleDateConverted
From PortfolioProject..NashvilleHousing

==============================================================================================================================================================================================

--2. Populate Property Address Data

Select *
From PortfolioProject..NashvilleHousing
Where PropertyAddress is Null

--Step 1 (Join the common ParcelID with Existing and NUll Property address)

Select A.ParcelID, A.PropertyAddress, B.ParcelID, B.PropertyAddress, ISNULL(A.PropertyAddress, B.PropertyAddress)
From PortfolioProject..NashvilleHousing as A
JOIN PortfolioProject..NashvilleHousing as B
	ON A.ParcelID = B.ParcelID
	AND A.UniqueID <> B.UniqueID
Where A.PropertyAddress is Null

--Step 2 (Populate the Null Values using common property address)

Update A --Note that updating a table using join, you need to use the ALLIAS NAME instead of TABLE NAME
SET PropertyAddress = ISNULL(A.PropertyAddress, B.PropertyAddress)
From PortfolioProject..NashvilleHousing as A
JOIN PortfolioProject..NashvilleHousing as B
	ON A.ParcelID = B.ParcelID
	AND A.UniqueID <> B.UniqueID
Where A.PropertyAddress is Null

==============================================================================================================================================================================================

--3. Breaking out Address into Individual Columns (Address, City, State)

--Step 1 (use sibstring to separate the address from the city)

Select SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress)-1) as Address
, SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+1 , LEN(PropertyAddress)) as City

From PortfolioProject..NashvilleHousing

--Step2 (Add the data to the existing table)

-- For Address
ALTER TABLE NashvilleHousing
ADD PropertySplitAddress nvarchar(255)

Update NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress)-1)
From PortfolioProject..NashvilleHousing

-- For City
ALTER TABLE NashvilleHousing
ADD PropertySplitCity nvarchar(255)

Update NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+1 , LEN(PropertyAddress))
From PortfolioProject..NashvilleHousing


--FOR OWNER ADRESS (Using PARSENAME)
Select OwnerAddress
From PortfolioProject..NashvilleHousing

--Step1 (Replacing the comma to dot, for the use of PARSENAME fnc)

Select 
PARSENAME(REPLACE(OwnerAddress, ',', '.'),3),
PARSENAME(REPLACE(OwnerAddress, ',', '.'),2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'),1)

From PortfolioProject..NashvilleHousing

--Step2 (Creating new column and inserting the data)

--For Address
ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress nvarchar(255)

Update NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'),3)

--For City
ALTER TABLE NashvilleHousing
ADD OwnerSplitCity nvarchar(255)

Update NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'),2)

--For State
ALTER TABLE NashvilleHousing
ADD OwnerSplitSate nvarchar(255)

Update NashvilleHousing
SET OwnerSplitSate = PARSENAME(REPLACE(OwnerAddress, ',', '.'),1)

==============================================================================================================================================================================================

--4. Change Y and N to Yes and No in column "Sold as Vacant"

--For Visual only and checking
Select DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
From PortfolioProject..NashvilleHousing
Group By SoldAsVacant
Order by 2

--Step1 (Replace all Y and N using CASE statement)
Select SoldAsVacant, 
CASE When SoldAsVacant = 'Y' Then 'Yes'
     When SoldAsVacant = 'N' Then 'No'
	 Else SoldAsVacant
	 END
From PortfolioProject..NashvilleHousing

--Step2 (Update the column of SoldAsVacant using the Replaced values)

Update NashvilleHousing
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' Then 'Yes'
     When SoldAsVacant = 'N' Then 'No'
	 Else SoldAsVacant
	 END

==============================================================================================================================================================================================

--5. Removing Duplicates

--Step1 (Create a CTE that will show the rows that has a duplicate)

WITH RowNumCTE AS (
Select *,
ROW_NUMBER() OVER (
PARTITION BY ParcelID,
			 PropertyAddress,
			 SalePrice,
			 SaleDate,
			 LegalReference
			 ORDER BY 
				UniqueID
				) as row_num

From PortfolioProject..NashvilleHousing 
				)

--Step2 (Select all the duplicate rows only)
Select *
From RowNumCTE
Where row_num > 1

--Step3 (Delete all the duplicate rows)
DELETE
From RowNumCTE
Where row_num > 1


==============================================================================================================================================================================================

--6. Delete Unused Columns
Select *
From PortfolioProject..NashvilleHousing 

-- Using Drop Column to delete the column that is not useful

ALTER TABLE PortfolioProject..NashvilleHousing
DROP COLUMN PropertyAddress, OwnerAddress, SaleDate, TaxDistrict

==============================================================================================================================================================================================


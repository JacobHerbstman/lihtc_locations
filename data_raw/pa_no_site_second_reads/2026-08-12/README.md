# Pennsylvania no-site second-read sources

Retrieved on 2026-08-12 for a narrow audit of Pennsylvania developments with
no retained site. These files are source evidence only. They do not authorize a
site addition or a geocoding query.

Files and original URLs:

- `pha_family_developments.html`: https://www.pha.phila.gov/housing/public-housing/about-developments/family-developments/
- `phfa_newport_2006.pdf`: https://www.phfa.org/forms/press_releases/2006/press_release_10122006.pdf
- `philadelphia_inventory_2019.pdf`: https://www.hivphilly.org/media/documents/PHFA_Philadelphia_Rental_Housing_Inventory_9-11-19.pdf
- `surrey_hill.html`: https://ndcassetmanagement.com/property/surrey-hill-apartments/
- `fayette_housing_needs.pdf`: https://www.faypenn.org/wp-content/uploads/2026/01/Fayette-County-PA-23-230-Housing-Needs-Assessment-Revised-6-25.pdf
- `chambersburg_townhomes.html`: https://chambersburgfamilytownhomes.wodagroup.com/
- `towns_governors_contact.html`: https://www.townsatgovernorssquare.com/Contact.aspx
- `negley_neighbors_hunt.html`: https://huntcapitalpartners.com/news/hunt-capital-partners-transfers-ownership-of-negley-neighbors-apartments-in-pittsburghs-east-liberty-neighborhood?page=7
- `community_ventures_projects.html`: https://community-ventures.org/projects/
- `hill_com_fire_publicsource.html`: https://www.publicsource.org/some-families-displaced-by-five-alarm-fire-are-in-limbo-where-will-they-go/

The SHA-256 of the byte-sorted list produced by
`manifest.sha256` contains one SHA-256 per frozen source file. Its own SHA-256
is:

`22b237ed8779beac72d8c76c21cd6abd1c82136be7bb113f64e852fb94b3dbcf`

`source_manifest.csv` maps each of those ten frozen source files to the exact
retrieval URL, retrieval date, and SHA-256. It is metadata and is not included
in `manifest.sha256`; the review task validates it against that byte manifest.
Its own SHA-256 is
`9ebb455aa4633016e5469d30193a75bd653287212277dbf88dd82cec9ff7ff24`.

Important interpretation limits:

- The Philadelphia Housing Authority page labels its address column `Office`.
  It therefore cannot by itself establish an exhaustive physical site.
- The Philadelphia and PHFA PDFs can document a scattered-site or historical
  scope conflict, but they are not independent confirmation of the current
  PHFA county-inventory address.
- Owner or manager property pages can corroborate a named property's current
  contact address, but do not automatically establish historical site scope.

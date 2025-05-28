import 'package:artbeat/models/nc_region_model.dart';

/// Database class for North Carolina ZIP codes by region
class NCZipCodeDatabase {
  /// Singleton instance
  static final NCZipCodeDatabase _instance = NCZipCodeDatabase._internal();

  /// Factory constructor
  factory NCZipCodeDatabase() => _instance;

  /// Private constructor
  NCZipCodeDatabase._internal();

  /// Map of ZIP codes to their region and county
  late final Map<String, NCZipCodeInfo> _zipCodeMap = _buildZipCodeMap();

  /// All defined NC regions
  final List<NCRegionModel> regions = [
    // MOUNTAIN REGION
    NCRegionModel(
      name: "Mountain",
      counties: [
        NCCountyModel(
          name: "Ashe County",
          zipCodes: [
            "28615",
            "28617",
            "28626",
            "28629",
            "28631",
            "28640",
            "28643",
            "28672",
            "28684",
            "28693",
            "28694"
          ],
        ),
        NCCountyModel(
          name: "Avery County",
          zipCodes: [
            "28604",
            "28616",
            "28622",
            "28646",
            "28652",
            "28653",
            "28657",
            "28662",
            "28664"
          ],
        ),
        NCCountyModel(
          name: "Buncombe County",
          zipCodes: [
            "28701",
            "28704",
            "28709",
            "28711",
            "28715",
            "28730",
            "28732",
            "28778",
            "28801",
            "28803",
            "28804",
            "28805",
            "28806"
          ],
        ),
        NCCountyModel(
          name: "Cherokee County",
          zipCodes: ["28781", "28901", "28902", "28903", "28905", "28906"],
        ),
        NCCountyModel(
          name: "Clay County",
          zipCodes: ["28902", "28904", "28909"],
        ),
        NCCountyModel(
          name: "Graham County",
          zipCodes: ["28702", "28733", "28771"],
        ),
        NCCountyModel(
          name: "Haywood County",
          zipCodes: [
            "28716",
            "28721",
            "28738",
            "28745",
            "28751",
            "28785",
            "28786"
          ],
        ),
        NCCountyModel(
          name: "Henderson County",
          zipCodes: [
            "28726",
            "28729",
            "28731",
            "28732",
            "28739",
            "28742",
            "28759",
            "28790",
            "28791",
            "28792"
          ],
        ),
        NCCountyModel(
          name: "Jackson County",
          zipCodes: [
            "28707",
            "28713",
            "28717",
            "28719",
            "28723",
            "28725",
            "28779",
            "28783",
            "28789"
          ],
        ),
        NCCountyModel(
          name: "Macon County",
          zipCodes: ["28734", "28741", "28744", "28763"],
        ),
        NCCountyModel(
          name: "Madison County",
          zipCodes: ["28743", "28753", "28754", "28787"],
        ),
        NCCountyModel(
          name: "Mitchell County",
          zipCodes: ["28705", "28714", "28740", "28749", "28755"],
        ),
        NCCountyModel(
          name: "Swain County",
          zipCodes: ["28713", "28719"],
        ),
        NCCountyModel(
          name: "Transylvania County",
          zipCodes: ["28708", "28712", "28718", "28768"],
        ),
        NCCountyModel(
          name: "Watauga County",
          zipCodes: [
            "28604",
            "28605",
            "28607",
            "28608",
            "28618",
            "28684",
            "28692"
          ],
        ),
        NCCountyModel(
          name: "Yancey County",
          zipCodes: ["28714", "28740", "28755"],
        ),
      ],
    ),

    // FOOTHILLS REGION
    NCRegionModel(
      name: "Foothills",
      counties: [
        NCCountyModel(
          name: "Alexander County",
          zipCodes: ["28636", "28678", "28681"],
        ),
        NCCountyModel(
          name: "Burke County",
          zipCodes: ["28612", "28637", "28655", "28666", "28671", "28690"],
        ),
        NCCountyModel(
          name: "Caldwell County",
          zipCodes: [
            "28601",
            "28606",
            "28611",
            "28630",
            "28638",
            "28645",
            "28661",
            "28667"
          ],
        ),
        NCCountyModel(
          name: "Catawba County",
          zipCodes: [
            "28601",
            "28602",
            "28603",
            "28609",
            "28610",
            "28613",
            "28650",
            "28658",
            "28673",
            "28678"
          ],
        ),
        NCCountyModel(
          name: "Cleveland County",
          zipCodes: [
            "28017",
            "28018",
            "28020",
            "28021",
            "28042",
            "28073",
            "28086",
            "28089",
            "28090",
            "28114",
            "28136",
            "28150",
            "28151",
            "28152"
          ],
        ),
        NCCountyModel(
          name: "Lincoln County",
          zipCodes: [
            "28006",
            "28033",
            "28037",
            "28080",
            "28092",
            "28093",
            "28168"
          ],
        ),
        NCCountyModel(
          name: "McDowell County",
          zipCodes: ["28752", "28761", "28762"],
        ),
        NCCountyModel(
          name: "Polk County",
          zipCodes: ["28722", "28750", "28756", "28773", "28782"],
        ),
        NCCountyModel(
          name: "Rutherford County",
          zipCodes: [
            "28018",
            "28040",
            "28043",
            "28074",
            "28114",
            "28139",
            "28160",
            "28167"
          ],
        ),
        NCCountyModel(
          name: "Wilkes County",
          zipCodes: [
            "28606",
            "28624",
            "28635",
            "28649",
            "28651",
            "28654",
            "28659",
            "28665",
            "28669",
            "28670",
            "28685",
            "28697"
          ],
        ),
      ],
    ),

    // PIEDMONT REGION
    NCRegionModel(
      name: "Piedmont",
      counties: [
        NCCountyModel(
          name: "Alamance County",
          zipCodes: [
            "27201",
            "27202",
            "27215",
            "27216",
            "27217",
            "27244",
            "27253",
            "27302",
            "27340",
            "27349"
          ],
        ),
        NCCountyModel(
          name: "Cabarrus County",
          zipCodes: [
            "28025",
            "28026",
            "28027",
            "28075",
            "28081",
            "28082",
            "28083",
            "28107",
            "28124"
          ],
        ),
        NCCountyModel(
          name: "Caswell County",
          zipCodes: [
            "27212",
            "27217",
            "27231",
            "27291",
            "27305",
            "27314",
            "27315",
            "27379"
          ],
        ),
        NCCountyModel(
          name: "Chatham County",
          zipCodes: [
            "27207",
            "27208",
            "27213",
            "27228",
            "27252",
            "27256",
            "27259",
            "27312",
            "27344"
          ],
        ),
        NCCountyModel(
          name: "Davidson County",
          zipCodes: [
            "27239",
            "27292",
            "27293",
            "27295",
            "27299",
            "27351",
            "27360",
            "27361"
          ],
        ),
        NCCountyModel(
          name: "Davie County",
          zipCodes: ["27006", "27014", "27028"],
        ),
        NCCountyModel(
          name: "Durham County",
          zipCodes: [
            "27503",
            "27560",
            "27701",
            "27703",
            "27704",
            "27705",
            "27707",
            "27709",
            "27712",
            "27713"
          ],
        ),
        NCCountyModel(
          name: "Forsyth County",
          zipCodes: [
            "27009",
            "27012",
            "27023",
            "27040",
            "27045",
            "27050",
            "27051",
            "27052",
            "27101",
            "27103",
            "27104",
            "27105",
            "27106",
            "27107",
            "27109",
            "27110",
            "27127"
          ],
        ),
        NCCountyModel(
          name: "Franklin County",
          zipCodes: ["27508", "27525", "27549", "27596"],
        ),
        NCCountyModel(
          name: "Granville County",
          zipCodes: [
            "27507",
            "27509",
            "27522",
            "27536",
            "27537",
            "27541",
            "27565",
            "27582",
            "27587"
          ],
        ),
        NCCountyModel(
          name: "Guilford County",
          zipCodes: [
            "27214",
            "27235",
            "27249",
            "27260",
            "27261",
            "27262",
            "27263",
            "27264",
            "27265",
            "27282",
            "27301",
            "27310",
            "27313",
            "27317",
            "27358",
            "27370",
            "27401",
            "27403",
            "27405",
            "27406",
            "27407",
            "27408",
            "27409",
            "27410",
            "27411"
          ],
        ),
        NCCountyModel(
          name: "Iredell County",
          zipCodes: [
            "28010",
            "28031",
            "28036",
            "28088",
            "28115",
            "28117",
            "28123",
            "28166",
            "28625",
            "28634",
            "28660",
            "28677",
            "28678",
            "28687",
            "28688",
            "28689"
          ],
        ),
        NCCountyModel(
          name: "Lee County",
          zipCodes: ["27330", "27332"],
        ),
        NCCountyModel(
          name: "Mecklenburg County",
          zipCodes: [
            "28031",
            "28036",
            "28078",
            "28105",
            "28126",
            "28202",
            "28203",
            "28204",
            "28205",
            "28206",
            "28207",
            "28208",
            "28209",
            "28210",
            "28211",
            "28212",
            "28213",
            "28214",
            "28215",
            "28216",
            "28217",
            "28226",
            "28227",
            "28262",
            "28269",
            "28270",
            "28273",
            "28277",
            "28278"
          ],
        ),
        NCCountyModel(
          name: "Montgomery County",
          zipCodes: ["27209", "27229", "27247", "27281", "27306", "27356"],
        ),
        NCCountyModel(
          name: "Moore County",
          zipCodes: [
            "27259",
            "27325",
            "27330",
            "27332",
            "28315",
            "28327",
            "28350",
            "28374",
            "28387",
            "28388"
          ],
        ),
        NCCountyModel(
          name: "Orange County",
          zipCodes: [
            "27243",
            "27278",
            "27510",
            "27514",
            "27516",
            "27517",
            "27583"
          ],
        ),
        NCCountyModel(
          name: "Person County",
          zipCodes: ["27541", "27572", "27573", "27574", "27583"],
        ),
        NCCountyModel(
          name: "Randolph County",
          zipCodes: [
            "27203",
            "27205",
            "27207",
            "27208",
            "27212",
            "27215",
            "27216",
            "27217",
            "27220",
            "27230",
            "27231",
            "27301",
            "27302",
            "27306",
            "27312",
            "27313"
          ],
        ),
        NCCountyModel(
          name: "Rockingham County",
          zipCodes: [
            "27006",
            "27011",
            "27013",
            "27016",
            "27017",
            "27018",
            "27019",
            "27020"
          ],
        ),
        NCCountyModel(
          name: "Rowan County",
          zipCodes: ["28023", "28025", "28026", "28027"],
        ),
        NCCountyModel(
          name: "Stanly County",
          zipCodes: ["28001", "28002", "28009"],
        ),
        NCCountyModel(
          name: "Union County",
          zipCodes: ["28025", "28079"],
        ),
      ],
    ),

    // SANDHILLS REGION
    NCRegionModel(
      name: "Sandhills",
      counties: [
        NCCountyModel(
          name: "Cumberland County",
          zipCodes: ["28301", "28303", "28304", "28305"],
        ),
        NCCountyModel(
          name: "Harnett County",
          zipCodes: ["27501", "27505", "27546"],
        ),
        NCCountyModel(
          name: "Hoke County",
          zipCodes: ["28376"],
        ),
        NCCountyModel(
          name: "Lee County",
          zipCodes: ["27330", "27332"],
        ),
        NCCountyModel(
          name: "Montgomery County",
          zipCodes: ["27209", "27306", "27371"],
        ),
        NCCountyModel(
          name: "Moore County",
          zipCodes: ["28315", "28327", "28374"],
        ),
        NCCountyModel(
          name: "Richmond County",
          zipCodes: ["28345", "28379"],
        ),
        NCCountyModel(
          name: "Scotland County",
          zipCodes: ["28352", "28364"],
        ),
      ],
    ),

    // COASTAL PLAIN REGION
    NCRegionModel(
      name: "Coastal Plain",
      counties: [
        NCCountyModel(
          name: "Pitt County",
          zipCodes: [
            "27811",
            "27812",
            "27827",
            "27828",
            "27829",
            "27833",
            "27834",
            "27835",
            "27836",
            "27837",
            "27852",
            "27858",
            "27871",
            "27879",
            "27884",
            "27888",
            "28513",
            "28530",
            "28586",
            "28590"
          ],
        ),
        NCCountyModel(
          name: "Lenoir County",
          zipCodes: [
            "28501",
            "28502",
            "28503",
            "28504",
            "28525",
            "28551",
            "28572"
          ],
        ),
        NCCountyModel(
          name: "Edgecombe County",
          zipCodes: [
            "27801",
            "27802",
            "27809",
            "27815",
            "27819",
            "27843",
            "27852",
            "27864",
            "27881",
            "27886"
          ],
        ),
        NCCountyModel(
          name: "Nash County",
          zipCodes: [
            "27557",
            "27803",
            "27804",
            "27807",
            "27816",
            "27856",
            "27868",
            "27878",
            "27882",
            "27891"
          ],
        ),
        NCCountyModel(
          name: "Craven County",
          zipCodes: [
            "28519",
            "28523",
            "28526",
            "28527",
            "28530",
            "28532",
            "28533",
            "28560",
            "28561",
            "28562",
            "28563",
            "28564",
            "28573",
            "28586"
          ],
        ),
        NCCountyModel(
          name: "Wayne County",
          zipCodes: [
            "27530",
            "27531",
            "27532",
            "27533",
            "27534",
            "27830",
            "27863",
            "28333",
            "28365",
            "28578"
          ],
        ),
        NCCountyModel(
          name: "Greene County",
          zipCodes: ["27888", "28538", "28554", "28580"],
        ),
        NCCountyModel(
          name: "Jones County",
          zipCodes: ["28522", "28555", "28573", "28585"],
        ),
        NCCountyModel(
          name: "Duplin County",
          zipCodes: [
            "28325",
            "28341",
            "28349",
            "28365",
            "28398",
            "28444",
            "28453",
            "28458",
            "28464",
            "28466",
            "28478",
            "28508",
            "28518",
            "28521",
            "28525",
            "28572",
            "28574",
            "28578"
          ],
        ),
      ],
    ),

    // COASTAL / OUTER BANKS REGION
    NCRegionModel(
      name: "Coastal",
      counties: [
        NCCountyModel(
          name: "New Hanover County",
          zipCodes: [
            "28401",
            "28402",
            "28403",
            "28405",
            "28406",
            "28407",
            "28409",
            "28411",
            "28412",
            "28428",
            "28429",
            "28449",
            "28480"
          ],
        ),
        NCCountyModel(
          name: "Dare County",
          zipCodes: [
            "27915",
            "27920",
            "27936",
            "27943",
            "27948",
            "27949",
            "27954",
            "27959",
            "27968",
            "27972",
            "27978",
            "27981"
          ],
        ),
        NCCountyModel(
          name: "Carteret County",
          zipCodes: [
            "28511",
            "28512",
            "28516",
            "28557",
            "28570",
            "28575",
            "28577",
            "28579",
            "28581",
            "28582",
            "28589",
            "28594"
          ],
        ),
        NCCountyModel(
          name: "Currituck County",
          zipCodes: [
            "27916",
            "27917",
            "27923",
            "27927",
            "27929",
            "27939",
            "27941",
            "27947",
            "27950",
            "27956",
            "27958",
            "27964",
            "27965",
            "27966"
          ],
        ),
        NCCountyModel(
          name: "Hyde County",
          zipCodes: ["27824", "27826", "27875", "27885", "27960"],
        ),
        NCCountyModel(
          name: "Brunswick County",
          zipCodes: [
            "28401",
            "28420",
            "28422",
            "28436",
            "28451",
            "28452",
            "28456",
            "28459",
            "28461",
            "28462",
            "28465",
            "28467",
            "28468",
            "28469",
            "28470",
            "28479"
          ],
        ),
      ],
    ),
  ];

  /// Returns all NC regions
  List<NCRegionModel> getAllRegions() => regions;

  /// Returns a region by name
  NCRegionModel? getRegionByName(String regionName) {
    return regions.firstWhere(
      (region) => region.name.toLowerCase() == regionName.toLowerCase(),
      orElse: () => throw Exception('Region not found: $regionName'),
    );
  }

  /// Returns counties for a given region
  List<NCCountyModel> getCountiesByRegion(String regionName) {
    final region = getRegionByName(regionName);
    return region?.counties ?? [];
  }

  /// Returns region and county info for a given ZIP code
  NCZipCodeInfo? getInfoForZipCode(String zipCode) {
    return _zipCodeMap[zipCode];
  }

  /// Returns true if the ZIP code belongs to North Carolina
  bool isNCZipCode(String zipCode) {
    return _zipCodeMap.containsKey(zipCode);
  }

  /// Returns a list of regions that a list of ZIP codes belong to
  List<String> getRegionsForZipCodes(List<String> zipCodes) {
    final Set<String> regionSet = {};

    for (final zipCode in zipCodes) {
      final info = getInfoForZipCode(zipCode);
      if (info != null) {
        regionSet.add(info.region);
      }
    }

    return regionSet.toList();
  }

  /// Returns a list of all ZIP codes in North Carolina
  List<String> getAllZipCodes() {
    return _zipCodeMap.keys.toList();
  }

  /// Returns a list of all ZIP codes in a given region
  List<String> getZipCodesByRegion(String regionName) {
    final List<String> zipCodes = [];
    final region = getRegionByName(regionName);

    if (region != null) {
      for (final county in region.counties) {
        zipCodes.addAll(county.zipCodes);
      }
    }

    return zipCodes;
  }

  /// Builds a map of ZIP codes to their region and county info for quick lookup
  Map<String, NCZipCodeInfo> _buildZipCodeMap() {
    final Map<String, NCZipCodeInfo> map = {};

    for (final region in regions) {
      for (final county in region.counties) {
        for (final zipCode in county.zipCodes) {
          map[zipCode] = NCZipCodeInfo(
            zipCode: zipCode,
            county: county.name,
            region: region.name,
          );
        }
      }
    }

    return map;
  }
}

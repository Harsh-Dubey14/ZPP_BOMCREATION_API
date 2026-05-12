@EndUserText.label: 'BOM Create Response'
define abstract entity ZA_BOM_CREATE_RES
{
  Material              : abap.char(40);
  Plant                 : abap.char(4);
  BillOfMaterialVariant : abap.char(2);

  Success               : abap_boolean;
  BaseUnit              : abap.unit(3);
  Message               : abap.char(255);
  ApiResponse           : abap.string;
}

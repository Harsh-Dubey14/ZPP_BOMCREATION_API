@EndUserText.label: 'BOM Create Request'
define root abstract entity ZA_BOM_CREATE_REQ
{
  Material                   : abap.char(40);
  Plant                      : abap.char(4);
  BillOfMaterialVariant      : abap.char(2);
  BillOfMaterialVariantUsage : abap.char(1);

  _Item : composition [1..*] of ZA_BOM_CREATE_ITEM_REQ;
}

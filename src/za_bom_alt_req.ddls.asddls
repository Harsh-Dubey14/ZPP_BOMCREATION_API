@EndUserText.label: 'Alternate BOM Request'
define abstract entity ZA_BOM_ALT_REQ
{
  Material                   : abap.char(40);
  Plant                      : abap.char(4);
  BillOfMaterialVariant      : abap.char(2);
  BillOfMaterialVariantUsage : abap.char(1);
}

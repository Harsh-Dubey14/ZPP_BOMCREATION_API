@EndUserText.label: 'Get Alternate BOM Items Request'
define abstract entity ZA_BOM_ALT_ITEMS_REQ
{
  Material              : abap.char(40);
  Plant                 : abap.char(4);
  BomUsage              : abap.char(1);
  BillOfMaterialVariant : abap.numc(2);
}

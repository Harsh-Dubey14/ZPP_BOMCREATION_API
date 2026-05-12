@EndUserText.label: 'Alternate BOM Item Response'
define abstract entity ZA_BOM_ALT_ITEM_RES
{
  BillOfMaterialItemNumber   : abap.char(4);
  BillOfMaterialComponent    : abap.char(40);
  BillOfMaterialItemQuantity : abap.dec(13,3);
  BillOfMaterialItemUnit     : abap.unit(3);

  _Header : association to parent ZA_BOM_ALT_RES;
}

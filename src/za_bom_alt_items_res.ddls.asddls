@EndUserText.label: 'Get Alternate BOM Item Response'
define abstract entity ZA_BOM_ALT_ITEMS_RES
{
  Material                   : abap.char(40);
  Plant                      : abap.char(4);
  BomUsage                   : abap.char(1);
  BillOfMaterialVariant      : abap.numc( 2 );

  BillOfMaterialItemNumber   : abap.char(4);
  BillOfMaterialComponent    : abap.char(40);
  BillOfMaterialItemUnit     : abap.unit(3);
  BillOfMaterialItemQuantity : abap.dec(13,3);
  BOMItemSorter              : abap.char(40);
  SortString                 : abap.char(40);
  Success                    : abap_boolean;
  Message                    : abap.char(255);
}

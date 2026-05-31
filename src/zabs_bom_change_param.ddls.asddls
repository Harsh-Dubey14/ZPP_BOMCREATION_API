@EndUserText.label: 'BOM Change Item Parameter'
define abstract entity ZABS_BOM_CHANGE_PARAM
{
  BillOfMaterial               : abap.char(8);
  BillOfMaterialCategory       : abap.char(1);
  BillOfMaterialVariant        : abap.char(2);
  BillOfMaterialVariantUsage   : abap.char(1);

  Material                     : matnr;
  Plant                        : werks_d;

  BillOfMaterialItemNodeNumber : abap.char(8);
  BillOfMaterialItemNumber     : abap.char(4);

  BillOfMaterialComponent      : matnr;

  @Semantics.quantity.unitOfMeasure: 'BillOfMaterialItemUnit'
  BillOfMaterialItemQuantity   : abap.dec(16,3);

  BillOfMaterialItemUnit       : meins;
  BOMItemDescription           : abap.char(40);
  BOMItemSorter                : abap.char(40);

  ChangeMode                   : abap.char(1);
}

@EndUserText.label: 'BOM Create Item Request'
define abstract entity ZA_BOM_CREATE_ITEM_REQ
{
  BillOfMaterialItemNumber    : abap.char(4);
  BillOfMaterialComponent     : abap.char(40);

  @Semantics.quantity.unitOfMeasure: 'BillOfMaterialItemUnit'
  BillOfMaterialItemQuantity  : abap.quan(13,3);

  @Semantics.unitOfMeasure: true
  BillOfMaterialItemUnit      : abap.unit(3);

  _Parent : association to parent ZA_BOM_CREATE_REQ;
}

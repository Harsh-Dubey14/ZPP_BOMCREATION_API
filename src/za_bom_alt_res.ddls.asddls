@EndUserText.label: 'Alternate BOM Response'
define abstract entity ZA_BOM_ALT_RES
{
  Material              : abap.char(40);
  Plant                 : abap.char(4);
  BillOfMaterialVariant : abap.char(2);
  Success               : abap_boolean;
  Message               : abap.char(255);

  _Item : composition [0..*] of ZA_BOM_ALT_ITEM_RES;
}

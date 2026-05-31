@EndUserText.label: 'Read BOM for Change'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_BOM_CHANGE_QUERY'
define root custom entity ZCE_BOM_CHANGE_READ
{
  key BomKey                       : abap.char(120);

      BillOfMaterial               : abap.char(8);
      BillOfMaterialCategory       : abap.char(1);
      BillOfMaterialVariant        : abap.char(2);
      BillOfMaterialVariantUsage   : abap.char(1);

      /*
       Required later for standard API PATCH key
      */
      BillOfMaterialVersion        : abap.char(4);
      HeaderChangeDocument         : abap.char(12);

      Material                     : abap.char(40);
      Plant                        : abap.char(4);

      BillOfMaterialItemNodeNumber : abap.char(8);
      BillOfMaterialItemNumber     : abap.char(4);
      BillOfMaterialItemCategory   : abap.char(1);
      BillOfMaterialComponent      : abap.char(40);

      @Semantics.quantity.unitOfMeasure: 'BillOfMaterialItemUnit'
      BillOfMaterialItemQuantity   : abap.dec(16,3);
      BOMHeaderQuantityInBaseUnit  : abap.dec(13,3);
      BOMHeaderBaseUnit            : abap.unit(3);
      HeaderValidityStartDate      : abap.dats;
      BOMVersionStatus             : abap.char(2);

      BillOfMaterialItemUnit       : abap.unit(3);
      BOMItemDescription           : abap.char(40);
      BOMItemSorter                : abap.char(40);

      IsProductionRelevant         : abap_boolean;

      /*
       Helper fields for UI save logic
       EXISTING -> fetched from BOM
       CHANGED  -> user changed existing row
       NEW      -> user added new row
      */
      RowStatus                    : abap.char(10);
      IsNew                        : abap_boolean;
      IsChanged                    : abap_boolean;

      Status                       : abap.char(20);
      Message                      : abap.char(255);
}

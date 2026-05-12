@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Interface View BOM Item'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_BOM_ITM_N as select from ztb_bom_itm_n
  association to parent ZI_BOM_HDR_N as _Header
    on $projection.BomId = _Header.BomId
{
    key bom_id as BomId,
    key item_no as ItemNo,
    item_category as ItemCategory,
    component as Component,
    quantity as Quantity,
    uom as Uom,
    item_text as ItemText,
    created_by as CreatedBy,
    created_at as CreatedAt,
    changed_by as ChangedBy,
    changed_at as ChangedAt,
     local_last_changed_at as LocalLastChangedAt,

      _Header
}

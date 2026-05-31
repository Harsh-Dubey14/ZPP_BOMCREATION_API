@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'consumption for bom item'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZC_BOM_ITM_N
  as projection on ZI_BOM_ITM_N
{
  key BomId,
  key ItemNo,
      ItemCategory,
      Component,
      Quantity,
      Uom,
      ItemText,
      SortString,
      CreatedBy,
      CreatedAt,
      ChangedBy,
      ChangedAt,
      LocalLastChangedAt,
      /* Associations */
      _Header : redirected to parent ZC_BOM_HDR_N
}

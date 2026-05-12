@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'consumption for header'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZC_BOM_HDR_N as projection on ZI_BOM_HDR_N
{
    key BomId,
    Material,
    Plant,
    BomUsage,
    AltBom,
    BaseQty,
    BaseUom,
    ValidFrom,
    Status,
    Message,
    ApiResponse,
    CreatedBy,
    CreatedAt,
    ChangedBy,
    ChangedAt,
    LocalLastChangedAt,
    /* Associations */
     _Item : redirected to composition child ZC_BOM_ITM_N
}

@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Interface View BOM Header'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZI_BOM_HDR_N
  as select from ztb_bom_hdr_n
  composition [0..*] of ZI_BOM_ITM_N as _Item
{
  key bom_id                as BomId,
      material              as Material,
      plant                 as Plant,
      bom_usage             as BomUsage,
      alt_bom               as AltBom,
      base_qty              as BaseQty,
      base_uom              as BaseUom,
      valid_from            as ValidFrom,
      bom_status            as BomStatus,
      status                as Status,
      message               as Message,
      api_response          as ApiResponse,
      @Semantics.user.createdBy: true
      created_by            as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at            as CreatedAt,
      @Semantics.user.localInstanceLastChangedBy: true
      changed_by            as ChangedBy,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      changed_at            as ChangedAt,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,

      _Item
}

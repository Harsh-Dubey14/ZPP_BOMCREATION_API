@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'value help for plant'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_PLANT_VH_n as select from I_PlantStdVH
{
    key Plant,
    PlantName
}

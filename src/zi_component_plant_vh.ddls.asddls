@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'material available in specific plant'
@Metadata.ignorePropagatedAnnotations: true
define view entity zi_component_plant_vh as select from  I_ProductPlantBasic            as a
    left outer join I_ProductDescription as b on a.Product = b.Product
   
{
  key a.Plant as Plant,
  key a.Product  as component,
      b.ProductDescription,
      a.BaseUnit as uom
}

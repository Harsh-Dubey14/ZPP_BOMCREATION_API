@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'interface for product and plant'
@Metadata.ignorePropagatedAnnotations: true
define view entity zi_product_plant_vh as select from I_ProductDescription 
{
  key Product,
      ProductDescription

}

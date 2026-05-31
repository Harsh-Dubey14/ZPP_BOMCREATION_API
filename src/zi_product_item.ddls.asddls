@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'interface for product item level'
@Metadata.ignorePropagatedAnnotations: true
define view entity zi_product_item
  as select from    I_Product            as a
    left outer join I_ProductDescription as b on a.Product = b.Product
{
  key a.Product  as component,
      b.ProductDescription,
      a.BaseUnit as uom
}

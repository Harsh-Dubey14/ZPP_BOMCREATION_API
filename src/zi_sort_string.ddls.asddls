@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'interface for sort string'
@Metadata.allowExtensions: true
define view entity zi_sort_string
  as select distinct from I_Product      as a
    left outer join       ztstyle_matrix as b on a.YY1_StyleCode1_PRD = b.style
{
  key a.Product,
  key b.style      as Style,
  key b.zcomb      as Zcomb,
      b.color_name as ColorName,
      b.sizes as sizes

}
where a.YY1_StyleCode1_PRD is not initial
group by
  a.Product,
  b.style,
  b.zcomb,
  b.color_name,
  b.sizes

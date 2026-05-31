CLASS zcl_bom_alt_items DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES: BEGIN OF ty_request,
             material              TYPE i_product-product,
             plant                 TYPE i_plant-Plant,
             bom_usage             TYPE c LENGTH 1,
             billofmaterialvariant TYPE c LENGTH 2,
           END OF ty_request.

    TYPES: BEGIN OF ty_item,
             material                     TYPE i_product-product,
             plant                        TYPE i_plant-Plant,
             bom_usage                    TYPE c LENGTH 1,
             billofmaterialvariant        TYPE c LENGTH 2,
             billofmaterialitemnumber     TYPE c LENGTH 4,
             billofmaterialcomponent      TYPE i_product-product,
             billofmaterialitemunit       TYPE i_billofmaterialitemtp_3-BillOfMaterialItemUnit,
             billofmaterialitemquantity   TYPE p LENGTH 16 DECIMALS 3,
             BOMItemSorter TYPE i_billofmaterialitemtp_3-BOMItemSorter,
             SortString TYPE i_billofmaterialitemtp_3-BOMItemSorter,
             success                      TYPE abap_boolean,
             message                      TYPE c LENGTH 255,
           END OF ty_item.

    TYPES ty_item_tab TYPE STANDARD TABLE OF ty_item WITH EMPTY KEY.

    CLASS-METHODS get_items
      IMPORTING
        is_request      TYPE ty_request
      RETURNING
        VALUE(rt_items) TYPE ty_item_tab.

ENDCLASS.



CLASS ZCL_BOM_ALT_ITEMS IMPLEMENTATION.


  METHOD get_items.

    DATA lv_alt_bom TYPE I_BillOfMaterialItemTP_3-BillOfMaterialVariant.

    lv_alt_bom = is_request-billofmaterialvariant.

    IF is_request-material IS INITIAL.

      APPEND VALUE #(
        material              = is_request-material
        plant                 = is_request-plant
        bom_usage             = is_request-bom_usage
        billofmaterialvariant = is_request-billofmaterialvariant
        success               = abap_false
        message               = 'Material is mandatory'
      ) TO rt_items.

      RETURN.

    ENDIF.

    IF is_request-plant IS INITIAL.

      APPEND VALUE #(
        material              = is_request-material
        plant                 = is_request-plant
        bom_usage             = is_request-bom_usage
        billofmaterialvariant = is_request-billofmaterialvariant
        success               = abap_false
        message               = 'Plant is mandatory'
      ) TO rt_items.

      RETURN.

    ENDIF.

    IF is_request-bom_usage IS INITIAL.

      APPEND VALUE #(
        material              = is_request-material
        plant                 = is_request-plant
        bom_usage             = is_request-bom_usage
        billofmaterialvariant = is_request-billofmaterialvariant
        success               = abap_false
        message               = 'BOM Usage is mandatory'
      ) TO rt_items.

      RETURN.

    ENDIF.

    IF is_request-billofmaterialvariant IS INITIAL.

      APPEND VALUE #(
        material              = is_request-material
        plant                 = is_request-plant
        bom_usage             = is_request-bom_usage
        billofmaterialvariant = is_request-billofmaterialvariant
        success               = abap_false
        message               = 'Alternate BOM is mandatory'
      ) TO rt_items.

      RETURN.

    ENDIF.

    " If user sends 03 but CDS stores 3, normalize for selection.
**    SHIFT lv_alt_bom LEFT DELETING LEADING '0'.

    IF lv_alt_bom IS INITIAL.
      lv_alt_bom = '0'.
    ENDIF.

    SELECT
      BillOfMaterialItemNumber,
      BillOfMaterialComponent,
      BillOfMaterialItemUnit,
      BillOfMaterialItemQuantity,
      BOMItemSorter
      FROM I_BillOfMaterialItemTP_3 WITH PRIVILEGED ACCESS
      WHERE Material                   = @is_request-material
        AND Plant                      = @is_request-plant
        AND BillOfMaterialVariantUsage = @is_request-bom_usage
        AND BillOfMaterialVariant      = @lv_alt_bom
        AND BillOfMaterialCategory     = 'M'
      INTO TABLE @DATA(lt_bom_items).

    IF lt_bom_items IS INITIAL.

      APPEND VALUE #(
        material              = is_request-material
        plant                 = is_request-plant
        bom_usage             = is_request-bom_usage
        billofmaterialvariant = is_request-billofmaterialvariant
        success               = abap_false
        message               = |No BOM items found for material { is_request-material }, plant { is_request-plant }, usage { is_request-bom_usage }, alternate BOM { is_request-billofmaterialvariant }|
      ) TO rt_items.

      RETURN.

    ENDIF.

    LOOP AT lt_bom_items INTO DATA(ls_bom_item).

      APPEND VALUE #(
        material                     = is_request-material
        plant                        = is_request-plant
        bom_usage                    = is_request-bom_usage
        billofmaterialvariant        = is_request-billofmaterialvariant
        billofmaterialitemnumber     = ls_bom_item-BillOfMaterialItemNumber
        billofmaterialcomponent      = ls_bom_item-BillOfMaterialComponent
        billofmaterialitemunit       = ls_bom_item-BillOfMaterialItemUnit
        billofmaterialitemquantity   = ls_bom_item-BillOfMaterialItemQuantity
         SortString  = ls_bom_item-BOMItemSorter
        bomitemsorter = ls_bom_item-BOMItemSorter
        success                      = abap_true
        message                      = 'BOM item found'
      ) TO rt_items.

    ENDLOOP.

  ENDMETHOD.
ENDCLASS.

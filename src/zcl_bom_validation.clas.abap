CLASS zcl_bom_validation DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES: BEGIN OF ty_result,
             material  TYPE i_product-product,
             plant     TYPE i_plant-plant,
             is_valid  TYPE abap_boolean,
             base_unit TYPE i_billofmaterialitemtp_3-billofmaterialitemunit,
             message   TYPE string,
           END OF ty_result.

    METHODS validate_material_plant
      IMPORTING
                iv_material      TYPE i_product-product
                iv_plant         TYPE i_plant-plant
      RETURNING VALUE(rs_result) TYPE ty_result.

ENDCLASS.



CLASS ZCL_BOM_VALIDATION IMPLEMENTATION.


  METHOD validate_material_plant.

    CLEAR rs_result.

    rs_result-material = iv_material.
    rs_result-plant    = iv_plant.
    rs_result-is_valid = abap_false.

    IF iv_material IS INITIAL.
      rs_result-message = 'Material is required'.
      RETURN.
    ENDIF.

    IF iv_plant IS INITIAL.
      rs_result-message = 'Plant is required'.
      RETURN.
    ENDIF.

    SELECT SINGLE
           product,
           plant
      FROM i_productplantbasic
      WHERE product = @iv_material
        AND plant   = @iv_plant
      INTO @DATA(ls_product_plant).

    IF sy-subrc <> 0.
      rs_result-message = |Material { iv_material } is not extended to plant { iv_plant }|.
      RETURN.
    ENDIF.

    SELECT SINGLE
           baseunit
      FROM i_product
      WHERE product = @iv_material
      INTO @rs_result-base_unit.

    IF rs_result-base_unit = 'ST'.
      rs_result-base_unit = 'PC'.
    ENDIF.


    rs_result-is_valid = abap_true.
    rs_result-message  = |Material { iv_material } exists in plant { iv_plant }|.

  ENDMETHOD.
ENDCLASS.

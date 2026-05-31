CLASS lhc_zi_bom_hdr_n DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR zi_bom_hdr_n RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR zi_bom_hdr_n RESULT result.

    METHODS createstandardbom FOR DETERMINE ON MODIFY
      IMPORTING keys FOR zi_bom_hdr_n~createstandardbom.

METHODS changeexistingbom FOR MODIFY
  IMPORTING keys FOR ACTION zi_bom_hdr_n~changeexistingbom
  RESULT result.

ENDCLASS.

CLASS lhc_zi_bom_hdr_n IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD createstandardbom.

    READ ENTITIES OF zi_bom_hdr_n IN LOCAL MODE
      ENTITY zi_bom_hdr_n
      ALL FIELDS
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_header).

    READ ENTITIES OF zi_bom_hdr_n IN LOCAL MODE
      ENTITY zi_bom_hdr_n BY \_item
      ALL FIELDS
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_item).

    LOOP AT lt_header INTO DATA(ls_header).

      DATA lt_bom_item TYPE zcl_bom_create_api=>ty_item_tab.

      LOOP AT lt_item INTO DATA(ls_item)
        WHERE bomid = ls_header-bomid.

        APPEND VALUE #(
          item_no       = ls_item-itemno
          item_category = ls_item-itemcategory
          component     = ls_item-component
          quantity      = ls_item-quantity
          uom           = ls_item-uom
          item_text     = ls_item-itemtext
          sort_string = ls_item-sortstring
        ) TO lt_bom_item.

      ENDLOOP.

      IF lt_bom_item IS INITIAL.

        MODIFY ENTITIES OF zi_bom_hdr_n IN LOCAL MODE
          ENTITY zi_bom_hdr_n
          UPDATE FIELDS ( status message apiresponse )
          WITH VALUE #(
            (
              bomid       = ls_header-bomid
              status      = 'ERROR'
              message     = 'No BOM items found for this request'
              apiresponse = ''
            )
          ).

        CONTINUE.

      ENDIF.

      DATA(ls_result) = zcl_bom_create_api=>create_bom(
        is_header = VALUE #(
          bom_id     = ls_header-bomid
          material   = ls_header-material
          plant      = ls_header-plant
          bom_usage  = ls_header-bomusage
          alt_bom    = ls_header-altbom
          base_qty   = ls_header-baseqty
          base_uom   = ls_header-baseuom
          valid_from = ls_header-validfrom
          bom_status = ls_header-BomStatus
        )
        it_item = lt_bom_item
      ).

      MODIFY ENTITIES OF zi_bom_hdr_n IN LOCAL MODE
        ENTITY zi_bom_hdr_n
        UPDATE FIELDS ( status message baseuom apiresponse )
        WITH VALUE #(
          (
            bomid       = ls_header-bomid
            status      = ls_result-status
            message     = ls_result-message
            baseuom     = ls_result-base_uom
            apiresponse = ls_result-api_response
          )
        ).

    ENDLOOP.

  ENDMETHOD.

  METHOD changeexistingbom.

    READ ENTITIES OF zi_bom_hdr_n IN LOCAL MODE
      ENTITY zi_bom_hdr_n
      ALL FIELDS
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_header).

    LOOP AT keys INTO DATA(ls_key).

      DATA(ls_param) = ls_key-%param.

      DATA(ls_result) = zcl_bom_change_api=>change_bom_item(
        is_item = VALUE #(
          bill_of_material       = ls_param-BillOfMaterial
          bom_category           = COND #( WHEN ls_param-BillOfMaterialCategory IS INITIAL THEN 'M'
                                           ELSE ls_param-BillOfMaterialCategory )
          alt_bom                = ls_param-BillOfMaterialVariant
          bom_usage              = COND #( WHEN ls_param-BillOfMaterialVariantUsage IS INITIAL THEN '1'
                                           ELSE ls_param-BillOfMaterialVariantUsage )
          material               = ls_param-Material
          plant                  = ls_param-Plant
          item_node_number       = ls_param-BillOfMaterialItemNodeNumber
          item_number            = ls_param-BillOfMaterialItemNumber
          component              = ls_param-BillOfMaterialComponent
          quantity               = ls_param-BillOfMaterialItemQuantity
          uom                    = ls_param-BillOfMaterialItemUnit
          item_text              = ls_param-BOMItemDescription
          sort_string            = ls_param-BOMItemSorter
          change_mode            = COND #( WHEN ls_param-ChangeMode IS INITIAL THEN 'U'
                                           ELSE ls_param-ChangeMode )
        )
      ).

      MODIFY ENTITIES OF zi_bom_hdr_n IN LOCAL MODE
        ENTITY zi_bom_hdr_n
        UPDATE FIELDS ( status message apiresponse )
        WITH VALUE #(
          (
            %tky        = ls_key-%tky
            status      = ls_result-status
            message     = ls_result-message
            apiresponse = ls_result-api_response
          )
        ).

      READ ENTITIES OF zi_bom_hdr_n IN LOCAL MODE
        ENTITY zi_bom_hdr_n
        ALL FIELDS
        WITH VALUE #( ( %tky = ls_key-%tky ) )
        RESULT DATA(lt_updated).

      IF lt_updated IS NOT INITIAL.
        APPEND VALUE #(
          %tky   = ls_key-%tky
          %param = lt_updated[ 1 ]
        ) TO result.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.
ENDCLASS.

CLASS lhc_bomapi DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR bomapi RESULT result.

    METHODS read FOR READ
      IMPORTING keys FOR READ bomapi RESULT result.

    METHODS lock FOR LOCK
      IMPORTING keys FOR LOCK bomapi.


    METHODS getnextaltbom FOR MODIFY
      IMPORTING keys   FOR ACTION bomapi~getnextaltbom
      RESULT    result.

    METHODS getalternatebomitems FOR MODIFY
      IMPORTING keys   FOR ACTION bomapi~getalternatebomitems
      RESULT    result.

    METHODS validatematerialplant FOR MODIFY
      IMPORTING keys FOR ACTION bomapi~validatematerialplant RESULT result.

 METHODS changebomitem FOR MODIFY
      IMPORTING keys FOR ACTION bomapi~changebomitem
      RESULT result.


ENDCLASS.

CLASS lhc_bomapi IMPLEMENTATION.

  METHOD read.
  ENDMETHOD.

  METHOD lock.
  ENDMETHOD.

*  METHOD get_global_authorizations.
*
*    IF requested_authorizations-%action-validatematerialplant = if_abap_behv=>mk-on.
*      result-%action-validatematerialplant = if_abap_behv=>auth-allowed.
*    ENDIF.
*
*
*
*  ENDMETHOD.

METHOD get_global_authorizations.

  IF requested_authorizations-%action-validatematerialplant = if_abap_behv=>mk-on.
    result-%action-validatematerialplant = if_abap_behv=>auth-allowed.
  ENDIF.

  IF requested_authorizations-%action-getnextaltbom = if_abap_behv=>mk-on.
    result-%action-getnextaltbom = if_abap_behv=>auth-allowed.
  ENDIF.

  IF requested_authorizations-%action-getalternatebomitems = if_abap_behv=>mk-on.
    result-%action-getalternatebomitems = if_abap_behv=>auth-allowed.
  ENDIF.

  IF requested_authorizations-%action-changebomitem = if_abap_behv=>mk-on.
    result-%action-changebomitem = if_abap_behv=>auth-allowed.
  ENDIF.

ENDMETHOD.

  METHOD getalternatebomitems.

    LOOP AT keys INTO DATA(ls_key).

      DATA(ls_param) = ls_key-%param.

      DATA(lt_items) = zcl_bom_alt_items=>get_items(
        is_request = VALUE #(
          material              = ls_param-material
          plant                 = ls_param-plant
          bom_usage             = ls_param-bomusage
          billofmaterialvariant = ls_param-billofmaterialvariant
        )
      ).

      LOOP AT lt_items INTO DATA(ls_item).

        APPEND VALUE #(
          %cid   = ls_key-%cid
          %param = VALUE #(
            material                   = ls_item-material
            plant                      = ls_item-plant
            bomusage                   = ls_item-bom_usage
            billofmaterialvariant      = ls_item-billofmaterialvariant
            billofmaterialitemnumber   = ls_item-billofmaterialitemnumber
            billofmaterialcomponent    = ls_item-billofmaterialcomponent
            billofmaterialitemunit     = ls_item-billofmaterialitemunit
            billofmaterialitemquantity = ls_item-billofmaterialitemquantity
            bomitemsorter = ls_item-bomitemsorter
            sortstring = ls_item-sortstring
            success                    = ls_item-success
            message                    = ls_item-message
          )
        ) TO result.

      ENDLOOP.

    ENDLOOP.

  ENDMETHOD.

  METHOD getnextaltbom.

    LOOP AT keys INTO DATA(ls_key).

      DATA(ls_param) = ls_key-%param.

      DATA(ls_response) = zcl_bom_next_alt=>get_next_alt_bom(
        is_request = VALUE #(
          material  = ls_param-material
          plant     = ls_param-plant
          bom_usage = ls_param-bomusage
        )
      ).

      APPEND VALUE #(
        %cid   = ls_key-%cid
        %param = VALUE #(
          material   = ls_response-material
          plant      = ls_response-plant
          bomusage   = ls_response-bom_usage
          nextaltbom = ls_response-next_alt_bom
          success    = ls_response-success
          message    = ls_response-message
        )
      ) TO result.

    ENDLOOP.

  ENDMETHOD.
  METHOD validatematerialplant.

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_key>).

      DATA(ls_param) = <ls_key>-%param.

      DATA(ls_result) = NEW zcl_bom_validation( )->validate_material_plant(
        iv_material = CONV matnr( ls_param-material )
        iv_plant    = CONV werks_d( ls_param-plant )
      ).

      APPEND VALUE #(
        %cid = <ls_key>-%cid
        %param = VALUE #(
          material = ls_result-material
          plant    = ls_result-plant
          isvalid  = ls_result-is_valid
          baseunit = ls_result-base_unit
          message  = ls_result-message
        )
      ) TO result.

    ENDLOOP.

  ENDMETHOD.
METHOD changebomitem.

  LOOP AT keys INTO DATA(ls_key).

    DATA(ls_param) = ls_key-%param.

    DATA(ls_result) = zcl_bom_change_api=>change_bom_item(
      is_item = VALUE #(
        bill_of_material = ls_param-billofmaterial
        bom_category     = COND #(
                             WHEN ls_param-billofmaterialcategory IS INITIAL
                             THEN 'M'
                             ELSE ls_param-billofmaterialcategory
                           )
        alt_bom          = ls_param-billofmaterialvariant
        bom_usage        = COND #(
                             WHEN ls_param-billofmaterialvariantusage IS INITIAL
                             THEN '1'
                             ELSE ls_param-billofmaterialvariantusage
                           )
        material         = ls_param-material
        plant            = ls_param-plant

        item_node_number = ls_param-billofmaterialitemnodenumber
        item_number      = ls_param-billofmaterialitemnumber

        component        = ls_param-billofmaterialcomponent
        quantity         = ls_param-billofmaterialitemquantity
        uom              = ls_param-billofmaterialitemunit

        item_text        = ls_param-bomitemdescription
        sort_string      = ls_param-bomitemsorter
        change_mode      = COND #(
                             WHEN ls_param-changemode IS INITIAL
                             THEN 'U'
                             ELSE ls_param-changemode
                           )
      )
    ).

    APPEND VALUE #(
      %cid   = ls_key-%cid
      %param = VALUE #(
        success                      = ls_result-success
        status                       = ls_result-status
        message                      = ls_result-message
        apiresponse                  = ls_result-api_response

        billofmaterial               = ls_param-billofmaterial
        billofmaterialcategory       = ls_param-billofmaterialcategory
        billofmaterialvariant        = ls_param-billofmaterialvariant
        billofmaterialvariantusage   = ls_param-billofmaterialvariantusage
        material                     = ls_param-material
        plant                        = ls_param-plant
        billofmaterialitemnodenumber = ls_param-billofmaterialitemnodenumber
        billofmaterialitemnumber     = ls_param-billofmaterialitemnumber
        billofmaterialcomponent      = ls_param-billofmaterialcomponent
        billofmaterialitemquantity   = ls_param-billofmaterialitemquantity
        billofmaterialitemunit       = ls_param-billofmaterialitemunit
      )
    ) TO result.

  ENDLOOP.

ENDMETHOD.

ENDCLASS.

CLASS lsc_zce_bom_api DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS finalize REDEFINITION.

    METHODS check_before_save REDEFINITION.

    METHODS save REDEFINITION.

    METHODS cleanup REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_zce_bom_api IMPLEMENTATION.

  METHOD finalize.
  ENDMETHOD.

  METHOD check_before_save.
  ENDMETHOD.

  METHOD save.
  ENDMETHOD.

  METHOD cleanup.
  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.

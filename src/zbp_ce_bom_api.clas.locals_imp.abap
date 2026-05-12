CLASS lhc_bomapi DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR bomapi RESULT result.

    METHODS read FOR READ
      IMPORTING keys FOR READ bomapi RESULT result.

    METHODS lock FOR LOCK
      IMPORTING keys FOR LOCK bomapi.

    METHODS createbom FOR MODIFY
      IMPORTING keys FOR ACTION bomapi~createbom RESULT result.

    METHODS getalternatebom FOR MODIFY
      IMPORTING keys FOR ACTION bomapi~getalternatebom RESULT result.

    METHODS validatematerialplant FOR MODIFY
      IMPORTING keys FOR ACTION bomapi~validatematerialplant RESULT result.

ENDCLASS.

CLASS lhc_bomapi IMPLEMENTATION.

  METHOD read.
  ENDMETHOD.

  METHOD lock.
  ENDMETHOD.

  METHOD get_global_authorizations.

    IF requested_authorizations-%action-ValidateMaterialPlant = if_abap_behv=>mk-on.
      result-%action-ValidateMaterialPlant = if_abap_behv=>auth-allowed.
    ENDIF.

    IF requested_authorizations-%action-CreateBOM = if_abap_behv=>mk-on.
      result-%action-CreateBOM = if_abap_behv=>auth-allowed.
    ENDIF.

    IF requested_authorizations-%action-GetAlternateBOM = if_abap_behv=>mk-on.
      result-%action-GetAlternateBOM = if_abap_behv=>auth-allowed.
    ENDIF.

  ENDMETHOD.

  METHOD validatematerialplant.

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_key>).

      DATA(ls_param) = <ls_key>-%param.

      DATA(ls_result) = NEW zcl_bom_validation( )->validate_material_plant(
        iv_material = CONV matnr( ls_param-Material )
        iv_plant    = CONV werks_d( ls_param-Plant )
      ).

      APPEND VALUE #(
        %cid = <ls_key>-%cid
        %param = VALUE #(
          Material = ls_result-material
          Plant    = ls_result-plant
          IsValid  = ls_result-is_valid
          BaseUnit = ls_result-base_unit
          Message  = ls_result-message
        )
      ) TO result.

    ENDLOOP.

  ENDMETHOD.

  METHOD createbom.
    "We will fill after validation class activates.
  ENDMETHOD.

  METHOD getalternatebom.
    "We will fill after create API skeleton activates.
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

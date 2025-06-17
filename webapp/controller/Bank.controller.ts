

import MessageToast from "sap/m/MessageToast";
import BusyIndicator from "sap/ui/core/BusyIndicator";
import Controller from "sap/ui/core/mvc/Controller";
import ODataModel from "sap/ui/model/odata/v2/ODataModel";

/**
 * @namespace zsalarypending.controller
 */
export default class bank extends Controller {

    public oDataModel: ODataModel;

    /*eslint-disable @typescript-eslint/no-empty-function*/
    public onInit(): void {
        this.oDataModel = new ODataModel("/sap/opu/odata/sap/ZUI_BANKINTEGRATION/", {
            defaultCountMode: "None"
        });
    }

    public onClickDelete() {
        let selectedData = (this.byId("RespTable") as any).getSelectedItems(),
            that = this;
        BusyIndicator.show();

        this.oDataModel.setDeferredGroups(["deleteItems"]);
        for (let index = 0; index < selectedData.length; index++) {
            const element = selectedData[index].getBindingContext()?.getObject() || {};

            if (!element) continue;

            this.oDataModel.create("/falsedelete", {}, {
                urlParameters: {
                    "Id": element.Id
                },
                headers: {
                    "If-Match": "*"
                },
                success: function () {
                    (that.byId("_IDGenSmartTable") as any).rebindTable(true);
                    BusyIndicator.hide();
                }
            })
        }
    }



    public onClickPost() {
        let selectedData = (this.byId("RespTable") as any).getSelectedItems(),
            that = this;
        let data = selectedData
            .map((element: any) => {
                let data1 = element.getBindingContext()?.getObject() || {};
                return {
                    "Id": data1.Id
                }
            })
        BusyIndicator.show();

        $.ajax({
            url: '/sap/bc/http/sap/ZHTTP_BANKRECEIPTACCPOST',
            method: "POST",
            contentType: "application/json",
            data: JSON.stringify(data),
            success: function (response) {
                MessageToast.show(response);
                (that.byId("_IDGenSmartTable") as any).rebindTable(true);
                BusyIndicator.hide();
            },
            error: function (error) {
                MessageToast.show("Posting failed: " + (error.responseText || "Unknown error"));
                BusyIndicator.hide();
            }
        });
    }
}
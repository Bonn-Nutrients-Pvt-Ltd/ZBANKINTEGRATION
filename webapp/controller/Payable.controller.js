sap.ui.define([
    "sap/ui/core/mvc/Controller",
    "sap/ui/model/odata/v2/ODataModel",
    "sap/m/MessageToast",
    "sap/ui/core/BusyIndicator"
], function (Controller, ODataModel, MessageToast, BusyIndicator) {
    "use strict";
    return Controller.extend("zpayable.controller.Payable", {

        onInit() {
            this.oDataModel = new ODataModel("/sap/opu/odata/sap/ZUI_BANKINTEGRATION", {
                defaultCountMode: "None"
            });
            this.getView().setModel(this.oDataModel);
        },

        onClickDelete() {
            let selectedData = this.byId("_IDGenSmartTable").getSelectedItems(),
                that = this;
            this.oDataModel.setDeferredGroups(["deleteItems"]);
            for (let index = 0; index < selectedData.length; index++) {
                const element = selectedData[index].getBindingContext()?.getObject() || {};

                if (!element) continue;

                this.oDataModel.create("/falsedelete", {}, {
                    urlParameters: {
                        "Vutdate": `datetime'${element.Vutdate.toISOString().replace("Z", "")}'`,
                        "Unit": `'${element.Unit}'`,
                        "Vutacode": `'${element.Vutacode}'`
                    },
                    headers: {
                        "If-Match": "*"
                    },
                    success: function () {
                        that.byId("_IDGenSmartTable").rebindTable(true);
                    }
                })

            }

        },
        onClickPost() {
            let selectedData = this.byId("_IDGenSmartTable").getSelectedItems(),
                that = this;

            let data = selectedData.map((item) => {
                const element = item.getBindingContext()?.getObject() || {};
                return {
                    "Vutdate": `datetime'${element.Vutdate.toISOString().replace("Z", "")}'`,
                    "Unit": `'${element.Unit}'`,
                    "Vutacode": `'${element.Vutacode}'`
                }
            })

            $.ajax({
                url: '/sap/bc/http/sap/ZHTTP_BANKPAYABLE',
                method: "POST",
                contentType: "application/json",
                data: JSON.stringify(data),
                success: function () {
                    MessageToast.show(data);
                    that.byId("_IDGenSmartTable").rebindTable(true);
                },
                error: function (error) {
                    MessageToast.show("Upload failed: " + (error.responseText || "Unknown error"));
                }
            });

        },
        browseAndUpload(oEvent) {
            var filename = this.byId("fileUploader").getValue()
            var that = this;
            var file = oEvent.getParameter("files") && oEvent.getParameter("files")[0];
            if (!file) {
                console.error("No file selected.");
                return;
            }
            if (window.FileReader) {
                var reader = new FileReader();
                reader.onload = function (e) {
                    var data = e.target.result;
                    try {
                        var workbook = XLSX.read(data, {
                            type: 'binary'
                        });
                        if (!workbook.SheetNames || workbook.SheetNames.length === 0) {
                            MessageToast.show("No sheets found in the Excel file.");
                            return;
                        }
                        var excelData = [];
                        var headers = [];
                        let datas = [];
                        workbook.SheetNames.forEach(function (sheetName) {
                            var worksheet = workbook.Sheets[sheetName];
                            excelData = XLSX.utils.sheet_to_row_object_array(worksheet);
                            headers = XLSX.utils.sheet_to_json(worksheet, { header: 1 })[0];

                            excelData.forEach(function (element) {
                                // var [day, month, year] = element["VutDate"].split("-");
                                // var formattedDate = `${year}${month}${day}`;

                                datas.push({
                                    vutdate: element["Voucher Date"],
                                    unit: element["Plant "]?.toString() || "",
                                    VutAcode: element["GL Account"]?.toString() || "",
                                    VutATag: element["Account Type"]?.toString() || "",
                                    vutaacode: element["Customer/Supplier/Employee"]?.toString() || "",
                                    vutamt: element["Amount"] || 0,
                                    custref: element["Reference No"]?.toString() || "",
                                    vutref: element["Reference No"]?.toString() || "",
                                    vutnart: element["Narration"]?.toString() || "",
                                    vutcostcd: element["Costing Head"]?.toString() || "",
                                    vutbgtcd: element["Budgeted Head"]?.toString() || "",
                                    vutloccd: element["Location Head"]?.toString() || "",
                                    vutemail: element["email"]?.toString() || "",
                                    uploadName: filename || ""
                                });

                            });

                            $.ajax({
                                url: '/sap/bc/http/sap/ZHTTP_BANKPAYABLE',
                                method: "POST",
                                contentType: "application/json",
                                data: JSON.stringify(datas),
                                success: function (response) {
                                    MessageToast.show(response);
                                    that.byId("_IDGenSmartTable").rebindTable(true);
                                },
                                error: function (error) {
                                    MessageToast.show("Upload failed: " + (error.responseText || "Unknown error"));
                                }
                            });

                        });

                    } catch (error) {
                        console.error("Error parsing the Excel file: ", error);
                    }
                };
                reader.onerror = function (error) {
                    console.error("Error reading file: ", error);
                };
                reader.readAsBinaryString(file);
            } else {
                console.error("FileReader is not supported in this browser.");
            }
        },

        onClickExport: function () {
            this.byId("_IDGenDialog").open();
        },
        onCloseDownloadDialog: function () {
            this.byId("_IDGenDialog").close();
        },
        onClickDownload() {
            var formData = new FormData();
            formData.append("filename", this.byId("_IDGenInput").getValue());
            BusyIndicator.show(0);
            $.ajax({
                url: "/sap/bc/http/sap/ZHTTP_BANKPAYABLEDNLD",
                method: "POST",
                data: formData,
                processData: false,
                contentType: false,
                success: function (result) {
                    const blob = new Blob([result], { type: "text/csv;charset=utf-8;" });
                    const url = URL.createObjectURL(blob);

                    const link = document.createElement("a");
                    link.setAttribute("href", url);
                    link.setAttribute("download", "bankupload.csv");
                    link.style.visibility = "hidden";

                    document.body.appendChild(link);
                    link.click();
                    document.body.removeChild(link);
                    BusyIndicator.hide();
                },
                error: function () {
                    BusyIndicator.hide();
                }
            });
        },
        _convertToCSV: function (data) {
            var csvRows = [];

            var headers = [
            ];
            csvRows.push(headers.join(","));

            data.forEach(function (item) {
                var row = [
                    item.Vutdate !== "NULL" ? item.Vutdate : "",
                    item.Unit !== "NULL" ? item.Unit : "",
                    item.Vutacode !== "NULL" ? item.Vutacode : "",
                    item.Vutatag !== "NULL" ? item.Vutatag : "",
                    item.Vutaacode !== "NULL" ? item.Vutaacode : "",
                    item.Vutamt !== "NULL" ? item.Vutamt : "",
                    item.Custref !== "NULL" ? item.Custref : "",
                    item.Vutref !== "NULL" ? item.Vutref : "",
                    item.Vutnart !== "NULL" ? item.Vutnart : "",
                    item.Vutcostcd !== "NULL" ? item.Vutcostcd : "",
                    item.Vutbgtcd !== "NULL" ? item.Vutbgtcd : "",
                    item.Vutloccd !== "NULL" ? item.Vutloccd : "",
                    item.Vutemail ? `"${item.Vutemail}"` : ""
                ];
                csvRows.push(row.join(","));
            });

            return csvRows.join("\n");
        },
        _downloadCSV: function (csvContent, fileName) {
            var blob = new Blob([csvContent], { type: "text/csv;charset=utf-8;" });
            var url = URL.createObjectURL(blob);

            var link = document.createElement("a");
            link.href = url;
            link.setAttribute("download", fileName);
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
        },
        onClickupload: function () {
            this.byId("uploadDialog").open();
        },
        uploadcsvfilechange:function(oEvent){
            this.file =  oEvent.getParameter("files") && oEvent.getParameter("files")[0];
            if (!this.file) {
                console.error("No file selected.");
                return;
            }
        },
        onUploadFile: function () {

            if (!this.file) {
                MessageToast.show("Please select a CSV file.");
                return;
            }
            if (window.FileReader) {
                var reader = new FileReader();
                reader.onload = function (e) {
                    var data = e.target.result;
                    console.log(data);
                    // send data to backend http service to process and save data
                };
                reader.onerror = function (error) {
                    console.error("Error reading file: ", error);
                };
                reader.readAsText(this.file);
            } else {
                console.error("FileReader is not supported in this browser.");
            }
            var that = this;
            

        },
        processCSVData: function (data) {
            var lines = data.split("\n");
            var headers = lines[0].split(",");
            var recordsToStore = [];

            for (var i = 1; i < lines.length; i++) {
                var obj = {};
                var currentline = lines[i].split(",");
                for (var j = 0; j < headers.length; j++) {
                    obj[headers[j].trim()] = currentline[j] ? currentline[j].trim() : "";
                }
                if (obj["Success Status"] === "R" || obj["Success Status"] === "E") {
                    recordsToStore.push({
                        "UTR": obj["UTR"],
                        "SuccessStatus": obj["Success Status"],
                        "PostingDate": obj["Posting Date"],
                        "UniqueTransactionId": obj["Unique Transaction Id"]
                    });
                }
            }
            if (recordsToStore.length > 0) {
                this.storeRecords(recordsToStore);
            } else {
                MessageToast.show("No records to store based on the criteria.");
            }
        },

        //for storing the data
        storeRecords: function (records) {
            var that = this;
            $.ajax({
                url: '/sap/bc/http/sap/ZHTTP_BANKPAYABLE',
                method: "POST",
                contentType: "application/json",
                data: JSON.stringify(records),
                success: function () {
                    MessageToast.show("Records uploaded successfully.");
                    that.byId("uploadDialog").close();
                    that.byId("_IDGenSmartTable").rebindTable(true);
                },
                error: function (error) {
                    MessageToast.show("Upload failed: " + (error.responseText || "Unknown error"));
                }
            });
        },

        onCloseDialog: function () {
            this.byId("uploadDialog").close();
        }

    })
})

sap.ui.define([
    "sap/ui/core/mvc/Controller",
    "sap/ui/model/odata/v2/ODataModel",
    "sap/m/MessageToast",
    "sap/ui/core/BusyIndicator"
], function (Controller, ODataModel, MessageToast, BusyIndicator) {
    "use strict";
    return Controller.extend("zpayable.controller.Payable", {

        // 
        onInit() {
            this.oDataModel = new ODataModel("/sap/opu/odata/sap/ZUI_BANKINTEGRATION", {
                defaultCountMode: "None"
            });
            this.getView().setModel(this.oDataModel);

            this.uploadedCombinations = []; // NEW
            this.lastUploadedFileName = ""; // NEW
        },

        onClickDelete() {
            let table = this.byId("_IDGenSmartTable").getTable();
            let selectedData = table.getSelectedIndices(),
                that = this;
            this.oDataModel.setDeferredGroups(["deleteItems"]);
            for (let index = 0; index < selectedData.length; index++) {
                const element = table.getContextByIndex(selectedData[index])?.getObject() || {};

                if (!element) continue;

                this.oDataModel.create("/falsedelete2", {}, {
                    urlParameters: {
                        "Vutdate": `'${element.Vutdate}'`,
                        "Unit": `'${element.Unit}'`,
                        "Vutacode": `'${element.Vutacode}'`,
                        "Createdtime": `time'PT${Math.floor(element.Createdtime.ms / 3600000)}H${Math.floor(element.Createdtime.ms / 60000) % 60}M${Math.floor(element.Createdtime.ms / 1000) % 60}S'`,
                        "InstructionRefNum":`'${element.InstructionRefNum}'`

                        // "Createdtime": this.msToHHMMSS(parseInt(element.Createdtime.ms))
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
            let table = this.byId("_IDGenSmartTable").getTable();
            let selectedData = table.getSelectedIndices(),
                that = this;

            let data = selectedData.map((item) => {
                const element = table.getContextByIndex(item)?.getObject() || {};
                return {
                    "Vutdate": element.Vutdate,
                    "Unit": element.Unit,
                    "Vutacode": element.Vutacode,
                    "Createdtime": this.msToHHMMSS(parseInt(element.Createdtime.ms)),
                    "InstructionRefNum":element.InstructionRefNum
                }
            })

            $.ajax({
                url: '/sap/bc/http/sap/ZHTTP_BANKPAYABLEPOST',
                method: "POST",
                contentType: "application/json",
                data: JSON.stringify(data),
                success: function (result) {
                    MessageToast.show(result);
                    that.byId("_IDGenSmartTable").rebindTable(true);
                },
                error: function (error) {
                    that.byId("_IDGenSmartTable").rebindTable(true);
                    MessageToast.show("Upload failed: " + (error || "Unknown error"));
                }
            });

        },
        
        browseAndUpload(oEvent) {
            var filename = this.byId("fileUploader").getValue();
            var that = this;
            var file = oEvent.getParameter("files") && oEvent.getParameter("files")[0];
            if (!file) {
                MessageToast.show("No file selected.");
                return;
            }
            BusyIndicator.show(0);
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

                            for (let element of excelData) {
                                let vutdate = element["Voucher Date"];
                                // let fileKey = `${vutdate}_${filename}`;
                                // if (that.uploadedCombinations.includes(fileKey)) {
                                //     MessageToast.show(`File already uploaded for Voucher Date: ${vutdate}`);
                                //     BusyIndicator.hide();
                                //     return;
                                // }

                                datas.push({
                                    vutdate: vutdate,
                                    unit: element["Plant "]?.toString() || "",
                                    VutAcode: element["GL Account"]?.toString() || "",
                                    VutATag: element["Account Type"]?.toString() || "",
                                    vutaacode: element["Customer/Supplier/Employee"]?.toString() || "",
                                    vutamt: element["Amount"] || 0,
                                    custref: element["Description (GL,Suplr,Cust,emp)"]?.toString() || "",
                                    vutref: element["Reference No"]?.toString() || "",
                                    vutnart: element["Narration"]?.toString() || "",
                                    vutcostcd: element["Costing Head"]?.toString() || "",
                                    vutbgtcd: element["Budgeted Head"]?.toString() || "",
                                    vutloccd: element["Location Head"]?.toString() || "",
                                    vutemail: element["email"]?.toString() || "",
                                    uploadName: filename || ""
                                });

                                // that.uploadedCombinations.push(fileKey); // NEW
                            }

                            // Set file name for download
                            // that.lastUploadedFileName = filename; // NEW

                            $.ajax({
                                url: '/sap/bc/http/sap/ZHTTP_BANKPAYABLE',
                                method: "POST",
                                contentType: "application/json",
                                data: JSON.stringify(datas),
                                success: function (response) {
                                    MessageToast.show(response);
                                    that.byId("_IDGenSmartTable").rebindTable(true);
                                    BusyIndicator.hide();
                                    that.byId("_IDGenInput").setValue(filename);
                                },
                                error: function (error) {
                                    MessageToast.show("Upload failed: " + (error.responseText || "Unknown error"));
                                    BusyIndicator.hide();
                                }
                            });

                        });

                    } catch (error) {
                        MessageToast.show("Error parsing the Excel file: " + error.message);
                        BusyIndicator.hide();
                    }
                };
                reader.onerror = function (error) {
                    MessageToast.show("Error reading file: " + error.message);
                };
                reader.readAsBinaryString(file);
            } else {
                MessageToast.show("FileReader is not supported in this browser.");
            }
        },

        onClickExport: function () {
            // const filename = this.lastUploadedFileName || "bankupload";
            // const cleanFileName = filename.replace(/\.[^/.]+$/, ""); // Remove .xlsx or other extensions
            // const input = this.byId("fileNameInput"); // Make sure your dialog has an Input with this ID
            // if (input) {
            //     input.setValue(cleanFileName);
            // }
            this.byId("_IDGenDialog").open();
        },
        
        onCloseDownloadDialog: function () {
            this.byId("_IDGenDialog").close();
        },
        
        onClickDownload() {
            var formData = new FormData();
            let that = this,
            file = this.byId("_IDGenInput").getValue();

            let newFileName = file.split(".");
            newFileName.pop();
            newFileName.push("csv");

            formData.append("filename", file);
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
                    link.setAttribute("download", newFileName.join(".")); // NEW
                    link.style.visibility = "hidden";
                    document.body.appendChild(link);
                    link.click();
                    document.body.removeChild(link);
                    BusyIndicator.hide();
                    that.byId("_IDGenDialog").close();
                },
                error: function () {
                    BusyIndicator.hide();
                }
            });
        },

        msToHHMMSS(ms) {
            // Convert milliseconds to total seconds
            const totalSeconds = Math.floor(ms / 1000);
            // Calculate hours, minutes, and seconds
            const hours = Math.floor(totalSeconds / 3600);
            const minutes = Math.floor((totalSeconds % 3600) / 60);
            const seconds = totalSeconds % 60;
            // Pad with zeroes if needed and format as HHMMSS
            return (
              String(hours).padStart(2, '0') +
              String(minutes).padStart(2, '0') +
              String(seconds).padStart(2, '0')
            );
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
        uploadcsvfilechange: function (oEvent) {
            this.file = oEvent.getParameter("files") && oEvent.getParameter("files")[0];
            if (!this.file) {
                MessageToast.show("No file selected.");
                return;
            }
        },
        onUploadFile: function () {
            let that = this;
            if (!this.file) {
                MessageToast.show("Please select a CSV file.");
                return;
            }

            let filename = this.lastUploadedFileName;

            if (window.FileReader) {
                var reader = new FileReader();
                reader.onload = function (e) {
                    var data = e.target.result;

                    // Let backend verify file content
                    $.ajax({
                        url: '/sap/bc/http/sap/ZHTTP_BANKPAYABLESHOW',
                        headers: { "filename": filename },
                        method: "POST",
                        contentType: "application/json",
                        data: data,
                        success: function (response) {
                            MessageToast.show(response);
                            that.byId("_IDGenSmartTable").rebindTable(true);
                            that.byId("uploadDialog").close();
                        },
                        error: function (error) {
                            MessageToast.show("Upload failed: " + (error.responseText || "Unknown error"));
                        }
                    });
                };
                reader.onerror = function (error) {
                    MessageToast.show("Error reading file: " + error.message);
                };

                reader.readAsText(this.file); // It auto handles CSV content regardless of file extension
            } else {
                MessageToast.show("FileReader is not supported in this browser.");
            }
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
                url: '/sap/bc/http/sap/ZHTTP_BANKPAYABLESHOW',
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
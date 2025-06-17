/*global QUnit*/

sap.ui.define([
	"zpayable/controller/Payable.controller"
], function (Controller) {
	"use strict";

	QUnit.module("Payable Controller");

	QUnit.test("I should test the Payable controller", function (assert) {
		var oAppController = new Controller();
		oAppController.onInit();
		assert.ok(oAppController);
	});

});

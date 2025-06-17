/*global QUnit*/
import Controller from "brpending/controller/Bank.controller";

QUnit.module("Bank Controller");

QUnit.test("I should test the Bank controller", function (assert: Assert) {
	const oAppController = new Controller("Bank");
	oAppController.onInit();
	assert.ok(oAppController);
});
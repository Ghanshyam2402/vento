xmlport 50105 "Create Contact WS XML"
{

    UseDefaultNamespace = true;
    Direction = Import;

    schema
    {
        textelement(NodeName1)
        {
            tableelement(RecContact; Contact)
            {
                MinOccurs = Once;
                UseTemporary = true;
                fieldattribute(ContactName; RecContact.Name) { }
                fieldattribute(ContactType; RecContact.Type) { }
                fieldattribute(CompanyNo; RecContact."Company No.") { }
                fieldattribute(SalespersonCode; RecContact."Salesperson Code") { }
                fieldattribute(Address; RecContact.Address) { }
                fieldattribute(Address2; RecContact."Address 2") { }
                fieldattribute(City; RecContact.City) { }
                fieldattribute(PhoneNo; RecContact."Phone No.") { }
                fieldattribute(MobilePhoneNo; RecContact."Mobile Phone No.") { }
                fieldattribute(EMail; RecContact."E-Mail") { }



                trigger OnAfterInsertRecord()
                BEGIN
                    MarketingSetup.Get();
                    MarketingSetup.TestField("Contact Nos.");
                    NewContact.Init();
                    NewContact.Validate("No.", NoSeriesMgt.GetNextNo(MarketingSetup."Contact Nos.", Today, TRUE));
                    NewContact.Insert();
                    SingleInstanceCodeunit.SetPONumber(NewContact."No.");

                    NewContact.Validate(Name, RecContact.Name);
                    NewContact.Validate(Type, RecContact.Type);
                    NewContact.Validate("Company No.", RecContact."Company Name");
                    NewContact.Validate("Salesperson Code", RecContact."Salesperson Code");
                    NewContact.Validate(Address, RecContact.Address);
                    NewContact.Validate("Address 2", RecContact."Address 2");
                    NewContact.Validate(City, RecContact.City);
                    NewContact.Validate("Phone No.", RecContact."Phone No.");
                    NewContact.Validate("Mobile Phone No.", RecContact."Mobile Phone No.");
                    NewContact.Validate("E-Mail", RecContact."E-Mail");

                    NewContact.Modify();

                END;

            }
        }
    }

    var
        NewContact: Record Contact;
        SingleInstanceCodeunit: Codeunit "Single Instance Codeunit";
        NoSeriesMgt: Codeunit "No. Series";
        MarketingSetup: Record "Marketing Setup";
}
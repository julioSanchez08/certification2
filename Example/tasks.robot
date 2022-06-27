*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Desktop
Library             RPA.Tables
Library             RPA.Dialogs
Library             Dialogs
Library             RPA.PDF
Library             RPA.FileSystem
Library             RPA.Archive


*** Tasks ***
pedir robots
    abrir pagina
    descargar ordenes
    ordenar los robots
    comprimir los pdf
    eliminar carpeta de pdf
    [Teardown]    Close Browser


*** Keywords ***
descargar ordenes
    Add heading    Insert URL
    Add text input    site    label=URL
    ${sitio} =    Run dialog
    Download    ${sitio.site}

ordenar los robots
    ${ordenes} =    Read table from CSV    orders.csv    header = True
    FOR    ${element}    IN    @{ordenes}
        ${e} =    set variable    'error'
        Wait Until Element Is Visible    class:modal-dialog
        Click Button    OK
        ordenar un robot    ${element}
        Click Button    Preview
        tomar imagenes de los robots    ${element}[Order number]
        WHILE    ${e} == 'error'
            TRY
                Click Button    Order
                guardar el recibo como pdf    ${element}[Order number]
                Click Button    Order another robot
                ${e} =    Set Variable    'OK'
            EXCEPT
                ${e} =    set variable    'error'
            END
        END
    END

ordenar un robot
    [Arguments]    ${ordenes}
    Select From List By Value    head    ${ordenes}[Head]
    Select Radio Button    body    ${ordenes}[Body]
    Input Text    class:form-control    ${ordenes}[Legs]
    Input Text    address    ${ordenes}[Address]

abrir pagina
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

guardar el recibo como pdf
    [Arguments]    ${num}
    ${nom} =    Set Variable    recibo${num}.pdf
    Wait Until Element Is Visible    id:receipt
    ${recibo} =    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${recibo}    ${OUTPUT_DIR}${/}ordenes${/}${nom}    overwrite=True
    Add Watermark Image To PDF
    ...    image_path=${OUTPUT_DIR}${/}ordenes${/}robot${num}.png
    ...    source_path=${OUTPUT_DIR}${/}ordenes${/}${nom}
    ...    output_path=${OUTPUT_DIR}${/}ordenes${/}${nom}
    Remove File    ${OUTPUT_DIR}${/}ordenes${/}robot${num}.png

tomar imagenes de los robots
    [Arguments]    ${num}
    Wait Until Element Is Visible    id:robot-preview
    ${nom} =    Set Variable    robot${num}.png
    Screenshot    id:robot-preview    ${OUTPUT_DIR}${/}ordenes${/}${nom}

comprimir los pdf
    ${recibos} =    Set Variable    ${OUTPUT_DIR}${/}ordenes.zip
    Archive Folder With Zip    ${OUTPUT_DIR}${/}ordenes    ${recibos}

eliminar carpeta de pdf
    Remove Directory    ${OUTPUT_DIR}${/}ordenes    True

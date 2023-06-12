import com.fasterxml.jackson.databind.JsonNode
import com.fasterxml.jackson.databind.ObjectMapper
import com.fasterxml.jackson.databind.node.ArrayNode
import com.fasterxml.jackson.databind.node.TextNode
import groovy.transform.Canonical

@Canonical
class AuthorizedEmailLRs {

    JsonNode availableLRs
    JsonNode procData
    Execution execution

//    AuthorizedEmailLRs(JsonNode availableLRs, JsonNode procData, Execution execution) {
//        this.availableLRs = availableLRs
//        this.procData = procData
//        this.execution = execution
//    }

    static void main(String[] args) {
//        println System.getProperty("user.dir")

        def procData = new ObjectMapper().readTree(new File('src/json', 'telcom01.json'))
        def availableLRs = procData.get('partyToLegalRelationship').findValues('legalRelationship')

        Map<String, Object> variables = [
                brIds: ['12345678', '66666666', '089080890', '565656565', '324234234', '11111111'].toSet()
        ]

        // 90909090 - no entitlement
        // 888887777 - Closed

        AuthorizedEmailLRs authorizedEmailLRs = new AuthorizedEmailLRs(
                new ObjectMapper().valueToTree(availableLRs),
                procData,
                new Execution(variables)
        )

        authorizedEmailLRs.script()

    }

    void script() {

        ObjectMapper objectMapper = new ObjectMapper()

        def availableLRsList = availableLRs.findValues('fullName')
        def selectedLRs = procData.get('telcoms').collect { it.get('contactUsageTelcom').toList() }.flatten() as List<JsonNode>

        def closedLRs = procData.get('telcoms').collect {
            def fullNames = it.get('contactUsageTelcom').findValues('fullName')
            fullNames.removeAll(availableLRsList.toList())
//            objectMapper.createArrayNode().addAll(fullNames)
            fullNames
        }

        def lrsWithoutEntitlementNames = []

        def brIds = execution.getVariable('brIds')
        def lrsWithoutEntitlementIds = procData.get('telcoms').collect { telcom ->
            def contactUsageTelcom = telcom.get('contactUsageTelcom')
            def lrsInTelcom = contactUsageTelcom.findValues('legalEntityNumber').collect { it.asText() }
            lrsInTelcom.removeAll(brIds)
            def fullNames = lrsInTelcom.collect { lr -> selectedLRs.find { lr == it.get('legalEntityNumber').asText() }.get('fullName').asText() }
            lrsWithoutEntitlementNames.add(fullNames)
            lrsInTelcom
        }

        def lrsToRemove = lrsWithoutEntitlementIds.flatten()
        def availableLRsIterator = availableLRs.elements()
        while (availableLRsIterator.hasNext()) {
            def lr = availableLRsIterator.next()
            if (lrsToRemove.contains(lr.get('legalEntityNumber').asText())) availableLRsIterator.remove()
        }

//        execution.setVariable('lrsWithoutEntitlementIds', objectMapper.createArrayNode().addAll(lrsWithoutEntitlementIds))
        execution.setVariable('lrsWithoutEntitlementIds', objectMapper.valueToTree(lrsWithoutEntitlementIds))
        execution.setVariable('lrsWithoutEntitlementNames', objectMapper.valueToTree(lrsWithoutEntitlementNames))
        execution.setVariable('closedLRs', objectMapper.valueToTree(closedLRs))
        execution.setVariable('availableLRs', availableLRs)
    }


}

@Canonical
class Execution {

    Map<String, Object> variables

//    Execution(Map<String, Object> variables) {
//        this.variables = variables
//    }

    static void setVariable(String variableName, Object value) {
        println "Setting variable '$variableName' to: $value"
    }

    Object getVariable(String variableName) {
        return variables[variableName]
    }

}
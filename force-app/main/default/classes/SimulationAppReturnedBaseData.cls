public class SimulationAppReturnedBaseData extends ResultTemplate{

    public SimulationAppBaseData data;
    
    public SimulationAppReturnedBaseData() {}

    public SimulationAppReturnedBaseData(SimulationAppBaseData simulationAppBaseData) {
        this.data = simulationAppBaseData;
        this.hasErrors = false;
        this.message = message;
    }

    public SimulationAppReturnedBaseData(String message){
        this.data = null;
        this.hasErrors = true;
        this.message = message;
    }
}
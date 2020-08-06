global class BatchIncentivePlanSchedulable implements Schedulable{
    global void execute(SchedulableContext sc) {
        try {
		    BatchIncentivePlan.run();
            String sch = '0 0 * * * ?';
            system.schedule('Incentive Plan Schedule Job', sch, new BatchIncentivePlanSchedulable());
        } catch(Exception e){
            system.debug('Error: ' + e);
        }
    }
}
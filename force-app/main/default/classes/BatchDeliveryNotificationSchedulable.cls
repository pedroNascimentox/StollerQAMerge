global class BatchDeliveryNotificationSchedulable implements Schedulable{
    global void execute(SchedulableContext sc) {
        try {
		    BatchDeliveryNotification.run();
            // String sch = '0 0 12 * * ?';
            // system.schedule('Delivery Notification Schedule Job', sch, new BatchDeliveryNotificationSchedulable());
        } catch(Exception e){
            system.debug('Error: ' + e);
        }
    }
}
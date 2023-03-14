### Project Documentation

**Stefano Costa**

#### Outline of project

- [Data Pre-Processing Notebook]( https://github.com/Charm-q/AI-Capstone/blob/main/Data%20Pre-Processing.ipynb)
- [Network Fingerprint AI Model Notebook]( https://github.com/Charm-q/AI-Capstone/blob/main//Network%20Fingerprint%20AI%20Model.ipynb)
- [Code for the deauth and data collection script]( https://github.com/Charm-q/AI-Capstone/blob/main/month-capture.sh)

#### Executive summary

I have captured network activity in my household using a network adapter in monitor mode. Network activity between a device and your wifi router is encrypted, however with a known wifi password and a [deauth technique]( https://en.wikipedia.org/wiki/Wi-Fi_deauthentication_attack) it is possible to capture the encryption handshake and then decrypt all network activity. While the contents of the network packets are still encrypted, the source, destination and several other high level details are visible. This is the same data your ISP or VPN can see. Given the network activity of two users on four devices (one laptop and one phone each), this project will be attempting to determine which user is which solely based on their internet activity.

An example of deauth attack on wifi is seen [here]( https://www.youtube.com/watch?v=O1TpBjoiLe4).

#### Rationale

The ability to fingerprint an individual based on their network activity is something law enforcement can use to track people on the internet. Additionally, ISPs and businesses are collecting this data and selling it to both law enforcement and advertisement companies. This will be a proof of concept on how easy it is to gather this data and identify individuals.

#### Research Question
Can I successfully train an AI model that can strongly distinguish between two individuals on four separate devices using only their encrypted TCP network activity?

#### Data Sources
Using the airmon-ng network attack libraries I setup a network adapter in monitor mode and capture all the data in my own household.

#### Methodology
- Capture a months worth of network activity of the household with a Linux security tool called [Aircrack-ng]( https://www.aircrack-ng.org/doku.php?id=airmon-ng). The custom script used to complete this capture is included [here]( https://github.com/Charm-q/AI-Capstone/blob/main/month-capture.sh).

- [Wireshark]( https://wiki.wireshark.org) is a tool used for analyzing network traffic. Use it to filter out junk data by only listening to a protocol known as TCP. MAC addresses are unique to each device so our model is ensured to have accurate training data.

- The network data is still encrypted at this point. Decrypt the handshakes with the known wifi password on Wireshark, details on how to do it are [here]( https://wiki.wireshark.org/HowToDecrypt802.11).

- Export the data to CSV and import the 2 millions entries into a Pandas dataframe in the [Data Pre-Processing Notebook]( https://github.com/Charm-q/AI-Capstone/blob/main/Data%20Pre-Processing.ipynb). 

![alt text](images/info.png)

- Inside the Pre-Processing notebook obfuscation of the unique MAC addresses is done privacy reasons.

![alt text](images/obfuscation.png)

- Devices on a local network communicate to each other automatically, this is not interesting data. Any entries with both the `Source address` and `Receiver address` belonging to our `targets` device list are filtered out.

- Only user activity is of interested so another filter is applied to remove any `Source address` that isn't in our `targets` device list. Anything else is a response from the domain the user is accessing and not actual user activity.

- Network frames are relatively small in size. A streaming service such as Netflix or Youtube will result in far more frames than something like Facebook or Reddit, even if the user spent more time on the latter. This skews the data but can be filtered out using the `Info` column. A `Client Hello` as the frame descriptor signifies a new connection to that domain. Filtering for it will give a better representation of the user's activity.

![alt text](images/client_hello.png)

- Drop unwanted columns that are leftover from Wireshark:
        -`No.` is the Wireshark index and not useful.
        - `Protocol` was previously filted by Wireshark for only TCP related protocols and therefore trivial.
        - `Info` defines activity based on TCP/IP frame info, this was useful for filtering by `Client Hello` but is no longer necessary.
        - `Receiver address` represents the MAC address of the destination device. Only the FQDN or domain listed in `Destination` is useful as often hosts have many servers with many MAC addresses.
        - `Source` is the FQDN of the user's device and is not constant. Only the MAC address listed in `Source address` is constant and useful.
        - `Length` could be useful, but since the data was filtered for only identical `Client Hello` frames then it becomes trivial.

![alt text](images/unwanted.png)

- The `Time` column refers to how long it has been since the network capture was started. Since the network capture was started on Wed Feb 1st, 2023 at 17:04.20 EST, it can be replaced by two separate and more useful columns. Namely the day of the week and the general time of day.

![alt text](images/timeofday.png)

- This concludes the data preprocessing. From around 2 millions entries, the data has been narrowed down to 1 thousand informative entries.

![alt text](images/preprocessed.png)


- In the Network Fingerprint AI Model[LINk!!!!] notebook the previously preprocessed data will be trained and fit to several models. The data needs to be One-Hot-Encoded first. This entails creating a separate column for each unique entry into the feature columns. This is necessary since the AI models train on numbers and not words.

![alt text](images/onehot.png)


- Two models will be used to learn the users habits. The [Support Vector Machine]( https://en.wikipedia.org/wiki/Support_vector_machine) needs to be used as it is very compatible for this classification. SVC essentially draws a line between points on a multidimensional graph. Since users tend to use the same websites at the same time of day, this is an excellent way of differentiating between the them. There will of course be some overlap so getting a perfect training and test score is impossible.


- To compare the results, a Neural Net model using a [MPLClassifer]( https://scikit-learn.org/stable/modules/generated/sklearn.neural_network.MLPClassifier.html) needs to be generated.


#### Results

The SVC train accuracy was ~92%, our SVC test accuracy was ~83%. Our best parameters are {'svc__coef0': 0, 'svc__gamma': 0.1, 'svc__kernel': 'linear'}. 

![alt text](images/svc.png)

The Neural Net using the MPLClassifer had a very similar test accuracy of ~83.

![alt text](images/net.png)

The results show that to an accuracy of 83% it is possible to differentiate between only two different people using only their encrypted TCP network data. The overlap from accessing big websites such as Google makes it impossible to get a perfect score. Since both models had very similar results then either one can be used for this task. However, scaling this up to many many people should prove a lot more technically challenging and one of the models will very likely be much more time consuming than the other.

#### Next Steps

Many more improvements can be made to increase the accuracy, reliability and scalability of the models. There are two types of changes that can be made, the first is to the dataset preprocessing and the second is to the actual AI models used. These next step outline only additional upgrades that can be made to the dataset as positive changes to the AI model itself cannot be known prior to testing.

- More Data:
    - Very simply, the first upgrade that can be done is to increase the size of the dataset by gathering network activity over a longer period of time. Additionally, this proof of concept only included two users which ends up being rather useful for large scale fingerprinting. Many more users network activity should be added to this model.

- Time and Size:
    - In the preprocessing, a filter was applied to only gather activity where the user initially connects to the website; the `Client Hello` frame. This is a good filtering technique to avoid skewed data. However, it removed information that was extractable such as the size of each frame, which would indicate the user's activity, as well as time spent on the website. Extracting these two features before filtering for `Client Hello` would improve the model greatly.
    
- Geographical Info:
    - To help train the model, all IP addresses that were accessed where converted to FQDNs in Wireshark. This was a good filtering method as the same website can have many IP addresses. When accessing a website, since users are generally directed to the closest server there was geographical information contained in those IP addresses that could be used to better differentiate individuals.

##### Contact and Further Information
